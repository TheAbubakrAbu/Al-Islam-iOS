#!/usr/bin/env python3
"""Merge, for every hadith on the shelf, the chains of narrators of every narration that carries its
text (and of the ones that say nearly the same thing) into one tree from the Prophet ﷺ down through
every fork to each compiler, and ship the trees: Resources/Data/Hadith/HadithIsnadTrees.qpk.

Abu, 2026-10-27: "in similar chains and similar Hadiths and show/share chain create one big chain
from prophet Muhammad and all the different forks and all the other chains ... Make all of this
preprocessed and efficient and done so beforehand".

What a tree is made of. A narration's family is itself and every row its similar list names
(SimilarHadiths.qpk: the same text under the same or another chain, and similar wording). Every
member whose chain the app can draw (HadithChains.qpk) contributes each of its roads as one path from
the Prophet ﷺ down to its compiler: the narrators top to bottom, a generation of two joint narrators
("حدثنا فلان وفلان قالا") giving one path through each. The paths are merged where they name the same
narrator (the shelf's narrator index, HadithNarrators.qpk: a name as written), and a relation ("أبيه",
"جده") is the relation of the narrator below it, merged only under the same one.

One join beyond the name as written (`join`), because the same man cited two ways ("عمر" and "عمر بن
الخطاب") would otherwise stand as two forks under the Prophet ﷺ: a shorter name is folded into the
fuller name it begins when that fuller name is the only one it fits among the narrators beside it
(the same narrator above, the same hadith), and, across every chain on the shelf under that same
narrator above, no other narrator of the shorter name is known, or the fuller one outnumbers every
other DOMINANCE to one. "سفيان" under يحيى بن سعيد is never joined to "سفيان بن عيينة" (the Thawri
narrates from him too); "عمر" under the Prophet ﷺ is joined to "عمر بن الخطاب" in the hadith of
intentions, where he is the only Umar beside it and outnumbers every other Umar there a hundred to
one. A relation is joined to another of the same word when the narrators they stand above are
joined. Nothing else is guessed: ابن شهاب and الزهري stay two narrators, as their profiles are. A tree
needs two chains at least; a row with one chain in its family (its own, or one similar row's) has no
tree, the chain sheet already draws it.

Where a chain does not name the Prophet ﷺ (the narrator's own words as written, or a report that
names him only inside the text), its path still hangs from the root, the narration marked as not
raised to him; the app draws that link dashed and says so. Nothing here raises a narration.

    python3 Scripts/build_isnad_trees.py             # writes the pack and UnitTests/HadithIsnadTreeSamples.swift
    python3 Scripts/build_isnad_trees.py --stats     # sizes and shapes, nothing written
    python3 Scripts/build_isnad_trees.py --inspect bukhari:1 muslim:7   # a row's tree as an outline

The pack is the app's pack container (the .qpk layout of QuranPack.swift, `write_pack`): the eager
section names the books in the catalog's order (a leaf names its compiler's book by that index) and
the counts; book n's block maps its rows to their trees (a row block by idInBook: varint tree id,
varint narrations, varint books), one tree being shared by every row whose family and chains come
to the same tree; the blocks after hold the trees, SHARD to a block by tree id, each tree written
in preorder (`serialize`): a flags byte (bits 0-1 the kind: 0 the Prophet ﷺ at the root, 1 a
narrator, 2 a compiler; bit 2 on a narrator when a narration beneath names the Prophet ﷺ), then
for a narrator varint ids (0 for a relation, followed by its text: u8 length, UTF-8), then that many
varint narrator ids, the fullest name first (the joined shorter forms after it), varint children; for a compiler u8 book, varint narrations, each varint idInBook and u8 raised. Names of
numbered narrators are not repeated here: the app reads them from the narrator index. Rerun after
any .hpk rebuild, after build_hadith_chains.py and after build_similar_hadiths.py (this reads both
packs); the samples test holds the pack to what the script built.

The hadiths with the most chains (Abu, 2026-11-23: "would be fire to see/filter Hadiths with the most
amount of chains ... as a filter thing or as another navigation link like most overlap most chains").
A row's fourth number is its CHAINS: how many different chains its narrations come down by, a chain
being the narrators as written from the top down to one compiler, counted once however many
narrations repeat it (the forty narrations of Hammam's sahifah in one book are one chain). It is
counted over a narrower family than the tree's, because two kinds of row are matched to rows that
are not the same hadith, and a count that ranks hadiths must not be led by them (`rank`):
  - a row whose own text only points at another ("عن النبي ﷺ مثله", "نحوه", "بهذا الإسناد"): ninety-six
    such rows carry the same three words and are each other's "same text". It counts no chains.
  - a row of at-Tirmidhi's, whose text ends in his own remarks ("وفي الباب عن ... هذا حديث حسن صحيح"):
    another row of his that is only SIMILAR to it may share nothing but those remarks. It is left
    out of the count; a row of his with the same text, or any other book's row, is counted.
The trees themselves are untouched by this (the tree of such a row still merges what its similar
list names). The last block lists the rows with the most chains, most first, one row for each
hadith (a row most of whose family is already listed is left out): the whole shelf's list, then
each book's own.

    python3 Scripts/build_isnad_trees.py --ranking 40    # the top of the shelf's list, nothing written
"""
import itertools
import json
import struct
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "Scripts"))
from islam_packs import Hadith  # noqa: E402
import build_hadith_chains as chains  # noqa: E402
import build_similar_hadiths as similar  # noqa: E402

OUT = ROOT / "Resources/Data/Hadith/HadithIsnadTrees.qpk"
SAMPLES = ROOT / "UnitTests/HadithIsnadTreeSamples.swift"
SLUGS = similar.SLUGS
KIND_ROOT, KIND_NARRATOR, KIND_LEAF = 0, 1, 2
FLAG_RAISED = 4
SHARD = 512
# A chain of several joint generations gives the product of their people as paths; past this many,
# only the first narrator of each joint generation is followed (never reached on the shelf as read).
MAX_PATHS = 64
# A shorter name joins the fuller one when, under the same narrator above across the shelf, the fuller
# one outnumbers every other narrator the shorter name fits this many to one (`dominant`).
DOMINANCE = 10
SAMPLE_ROWS = [("bukhari", 1), ("muslim", 7), ("tirmidhi", 1), ("nasai", 1), ("riyad_assalihin", 1), ("nawawi40", 1),
               ("bukhari", 54), ("ibnmajah", 4137)]
# A hadith is listed among those with the most chains from this many chains up.
MIN_RANKED = 3
# The words a row that only points at another narration is made of, beside the opening words and the
# honorifics (`similar.LEAD_IN`, `similar.NOISE`): "مثله", "نحوه", "بهذا الإسناد", "فذكر الحديث".
POINTER = {'مثله', 'بمثله', 'نحوه', 'بنحوه', 'مثل', 'بمثل', 'نحو', 'بنحو', 'نحوا', 'ذلك', 'فذكر', 'فذكره', 'يذكر', 'وذكر',
           'ذكر', 'معناه', 'بمعناه', 'الحديث', 'حديث', 'حديثه', 'بحديث', 'بهذا', 'هذا', 'بهذه', 'هذه', 'الاسناد',
           'باسناده', 'سواء', 'يفعل', 'القصه'}


# MARK: - What the two packs say

class Node:
    """A node of a chain code, as `chains.Node` with the narrator id the code names."""
    __slots__ = ('first', 'last', 'verb', 'aside', 'joint', 'narrator')

    def __init__(self, first, last, verb, aside, joint, narrator):
        self.first, self.last, self.verb, self.aside, self.joint, self.narrator = first, last, verb, aside, joint, narrator


def parse_layers(text):
    layers = []
    for layer_text in text.split('|'):
        layer = []
        for node_text in layer_text.split('+'):
            narrator = None
            if '@' in node_text:
                node_text, found = node_text.split('@')
                narrator = int(found)
            joint = node_text.endswith('j')
            if joint:
                node_text = node_text[:-1]
            numbers = [int(x) for x in node_text.split('.')]
            assert len(numbers) in (3, 5), node_text
            layer.append(Node(numbers[0], numbers[1], numbers[2], tuple(numbers[3:5]) if len(numbers) == 5 else None,
                              joint, narrator))
        layers.append(layer)
    return layers


def parse_code(code):
    """The mirror of `HadithChainDecoder.parse` (HadithChains.swift)."""
    if '~' in code:
        code, _ = code.split('~')
    count, body = code.split(':', 1)
    prophet = '!' in body
    if prophet:
        body, _ = body.split('!')
    branches = []
    if '=' in body:
        roads, body = body.split('=')
        for road in roads.split('#'):
            layers_text, _, _ = road.partition('^')
            branches.append(parse_layers(layers_text))
    return dict(count=int(count), branches=branches, shared=parse_layers(body), prophet=prophet)


def read_chains():
    """{(slug, idInBook): (parsed code, raw tokens, folded keys)} for every chain the app draws, and
    the compilers' names by slug."""
    eager, blocks, fields = chains.read_container(chains.OUT)
    pos = 4
    books = []
    for _ in range(struct.unpack_from('<I', eager, 0)[0]):
        found = []
        for _ in range(2):
            length = struct.unpack_from('<I', eager, pos)[0]
            found.append(eager[pos + 4:pos + 4 + length].decode('utf-8'))
            pos += 4 + length
        books.append((found[0], found[1], struct.unpack_from('<I', eager, pos)[0]))
        pos += 4
    out, compilers = {}, {}
    for (slug, compiler, count), raw_block in zip(books, blocks):
        compilers[slug] = compiler
        shelf = Hadith(slug)
        by_id = {row.idInBook: index for index, row in enumerate(shelf.rows)}
        for id_in_book, payload in chains.rows_of(raw_block, count):
            item = shelf.item(by_id[id_in_book])
            raw = item.arabic.split()
            parsed = parse_code(payload.decode('ascii'))
            assert parsed['count'] == len(raw), (slug, id_in_book)
            out[(slug, id_in_book)] = (parsed, raw, [chains.key(t) for t in raw])
    return out, compilers


def read_similar():
    """{(slug, idInBook): [(slug, idInBook, tier), ...]} as SimilarHadiths.qpk lists them."""
    eager, blocks, fields = chains.read_container(similar.OUT)
    pos = 4
    books = []
    for _ in range(struct.unpack_from('<I', eager, 0)[0]):
        length = struct.unpack_from('<I', eager, pos)[0]
        slug = eager[pos + 4:pos + 4 + length].decode('utf-8')
        pos += 4 + length
        books.append((slug, struct.unpack_from('<I', eager, pos)[0]))
        pos += 4
    assert [slug for slug, _ in books] == SLUGS
    out = {}
    for (slug, count), raw_block in zip(books, blocks):
        for id_in_book, payload in chains.rows_of(raw_block, count):
            at, matches = 0, []
            while at < len(payload):
                (book, other, tier, _, _, _), at = similar.unpack_record(payload, at)
                matches.append((SLUGS[book], other, tier))
            out[(slug, id_in_book)] = matches
    return out


def read_names():
    """{narrator id: name} from HadithNarrators.qpk, for the outline and the samples."""
    eager, blocks, fields = chains.read_container(chains.NARRATORS_OUT)
    pos = 4
    for _ in range(struct.unpack_from('<I', eager, 0)[0]):
        pos += 4 + struct.unpack_from('<I', eager, pos)[0]
    count = struct.unpack_from('<I', eager, pos)[0]
    names = {}
    for narrator_id, payload in chains.rows_of(blocks[0], count):
        length = struct.unpack_from('<I', payload, 0)[0]
        names[narrator_id] = payload[4:4 + length].decode('utf-8')
    return names


# MARK: - The tree

class Tree:
    __slots__ = ('kind', 'narrator', 'ids', 'texts', 'children', 'book', 'refs', 'raised', 'leaves', 'first')

    def __init__(self, kind, narrator=0, book=None):
        self.kind, self.narrator, self.book = kind, narrator, book
        # Every narrator id joined into this node, the fullest name first; {0} at the root.
        self.ids = [narrator] if narrator else []
        self.texts = Counter()
        self.children = {}
        self.refs = set()
        self.raised = False
        self.leaves = 0
        self.first = None

    @property
    def relation(self):
        return self.kind == KIND_NARRATOR and not self.narrator


WORDS = {}
# Across the shelf: who narrates from whom, by narrator id (0 for the Prophet ﷺ), as the chains name them.
BELOW = defaultdict(Counter)


def shelf_links(chain_rows):
    """Fill WORDS (a narrator id's folded name, as `narrator_key` files it) and BELOW."""
    for (slug, id_in_book), (parsed, raw, keys) in chain_rows.items():
        for path in paths(parsed):
            above = 0 if parsed['prophet'] else None
            for node in path:
                if node.narrator:
                    if node.narrator not in WORDS:
                        WORDS[node.narrator] = tuple((chains.narrator_key(chains.node_key(node, keys)) or '').split())
                    if above is not None:
                        BELOW[above][node.narrator] += 1
                    above = node.narrator
                else:
                    above = None


def is_prefix(short, full):
    return 0 < len(short) < len(full) and full[:len(short)] == short


def dominant(above, short, full_ids):
    """Across the shelf, under the narrators `above`, does the narrator `full_ids` stand alone among
    those the shorter name fits, or outnumber each of the others DOMINANCE to one?"""
    found = Counter()
    for parent in above:
        for child, count in BELOW[parent].items():
            if is_prefix(short, WORDS.get(child, ())):
                found[child] += count
    own = sum(found[i] for i in full_ids)
    others = max((count for child, count in found.items() if child not in full_ids), default=0)
    return others == 0 or own >= DOMINANCE * others


def absorb(into, other):
    """`other` becomes part of `into`: its ids, its spellings, its narrations, its children by key."""
    for narrator_id in other.ids:
        if narrator_id not in into.ids:
            into.ids.append(narrator_id)
    into.ids.sort(key=lambda i: (-len(WORDS.get(i, ())), i))
    if into.kind == KIND_NARRATOR and into.ids:
        into.narrator = into.ids[0]
    into.texts += other.texts
    into.refs |= other.refs
    for key, child in other.children.items():
        if key in into.children:
            absorb(into.children[key], child)
        else:
            into.children[key] = child


def join(node):
    """Fold each child whose name is the beginning of exactly one other child's (the header says when),
    then each relation into the one of the same word whose narrator below it is joined likewise, and
    go on below."""
    named = {c.narrator: c for c in node.children.values() if c.kind == KIND_NARRATOR and c.narrator}
    for narrator_id in sorted(named, key=lambda i: (len(WORDS.get(i, ())), i)):
        short = named.get(narrator_id)
        if short is None:
            continue
        words = WORDS.get(narrator_id, ())
        fuller = [c for c in named.values() if c is not short and any(is_prefix(words, WORDS.get(i, ())) for i in c.ids)]
        if len(fuller) != 1:
            continue
        full = fuller[0]
        if not node.relation and not dominant(node.ids or [0], words, set(full.ids)):
            continue
        absorb(full, short)
        del named[narrator_id]
        node.children = {k: c for k, c in node.children.items() if c is not short}
    relations = [(k, c) for k, c in node.children.items() if c.relation and isinstance(k[2], tuple) and k[2][0] != 'book']
    for key, short in relations:
        if key not in node.children:
            continue
        _, text, (anchor, distance) = key
        words = WORDS.get(anchor, ())
        fuller = [(k, c) for k, c in node.children.items()
                  if c is not short and c.relation and k[1] == text and isinstance(k[2], tuple) and k[2][0] != 'book'
                  and k[2][1] == distance and is_prefix(words, WORDS.get(k[2][0], ()))]
        if len(fuller) != 1:
            continue
        absorb(fuller[0][1], short)
        del node.children[key]
    for child in list(node.children.values()):
        if child.kind != KIND_LEAF:
            join(child)


def paths(parsed):
    """Every road of a chain as a list of nodes top to bottom (the Prophet ﷺ and the compiler left
    out): the shared part, then each branch; a joint generation gives a path through each of its
    narrators."""
    top_down = list(reversed(parsed['shared']))
    roads = [top_down + list(reversed(layers)) for layers in parsed['branches']] or [top_down]
    out = []
    for road in roads:
        combos = 1
        for layer in road:
            combos *= len(layer)
        if combos > MAX_PATHS:
            out.append([layer[0] for layer in road])
        else:
            out.extend(list(combo) for combo in itertools.product(*road))
    return out


def path_keys(path, book, keys):
    """What each node of a path is merged by: the narrator id, or for a relation ("أبيه") its folded
    text under the first numbered narrator below it (the one it is the relation of), at that distance."""
    out = []
    for index, node in enumerate(path):
        if node.narrator:
            out.append(('n', node.narrator))
            continue
        anchor = next(((other.narrator, j - index) for j, other in enumerate(path) if j > index and other.narrator), None)
        out.append(('r', chains.node_key(node, keys), anchor or ('book', book)))
    return out


def build_tree(members, chain_rows):
    """One tree over the chains of `members` [(slug, idInBook)]: paths merged from the root down."""
    root = Tree(KIND_ROOT)
    for slug, id_in_book in members:
        parsed, raw, keys = chain_rows[(slug, id_in_book)]
        book = SLUGS.index(slug)
        for path in paths(parsed):
            current = root
            for node, key in zip(path, path_keys(path, book, keys)):
                child = current.children.get(key)
                if child is None:
                    child = current.children[key] = Tree(KIND_NARRATOR, narrator=node.narrator or 0)
                if not node.narrator:
                    child.texts[chains.node_text(raw, node)] += 1
                current = child
            leaf = current.children.get(('book', book))
            if leaf is None:
                leaf = current.children[('book', book)] = Tree(KIND_LEAF, book=book)
            leaf.refs.add((id_in_book, parsed['prophet']))
    root.ids = [0]
    join(root)
    settle(root)
    return root


def settle(node):
    """Counts and the canonical order: the largest subtree first, then the shelf's order of the first
    narration beneath; a compiler's narrations by number."""
    if node.kind == KIND_LEAF:
        node.leaves = 1
        node.raised = any(raised for _, raised in node.refs)
        node.refs = sorted(node.refs)
        node.first = (node.book, node.refs[0][0])
        return
    for child in node.children.values():
        settle(child)
    ordered = sorted(node.children.values(), key=lambda c: (-c.leaves, c.first))
    node.children = ordered
    node.leaves = sum(c.leaves for c in ordered)
    node.raised = any(c.raised for c in ordered)
    node.first = ordered[0].first


def serialize(node, out=None):
    out = bytearray() if out is None else out
    flags = node.kind | (FLAG_RAISED if node.kind == KIND_NARRATOR and node.raised else 0)
    out.append(flags)
    if node.kind == KIND_LEAF:
        out.append(node.book)
        out += similar.varint(len(node.refs))
        for id_in_book, raised in node.refs:
            out += similar.varint(id_in_book) + bytes([1 if raised else 0])
        return out
    if node.kind == KIND_NARRATOR:
        out += similar.varint(len(node.ids))
        if not node.ids:
            text = node.texts.most_common(1)[0][0].encode('utf-8')
            assert len(text) < 256
            out += bytes([len(text)]) + text
        for narrator_id in node.ids:
            out += similar.varint(narrator_id)
    out += similar.varint(len(node.children))
    for child in node.children:
        serialize(child, out)
    return out


def outline(node, names, depth=0, lines=None):
    """The tree as lines, one per node in preorder: what the samples test rebuilds from the app's decoding."""
    lines = [] if lines is None else lines
    if node.kind == KIND_ROOT:
        lines.append(f'{depth}:root')
    elif node.kind == KIND_LEAF:
        refs = ','.join(f'{i}{"^" if raised else ""}' for i, raised in node.refs)
        lines.append(f'{depth}:{SLUGS[node.book]}:{refs}')
    else:
        text = names.get(node.narrator, '') if node.narrator else node.texts.most_common(1)[0][0]
        ids = '+'.join(str(i) for i in node.ids) if node.ids else '0'
        lines.append(f'{depth}:{ids}{"^" if node.raised else ""}:{text}')
    for child in node.children if node.kind != KIND_LEAF else []:
        outline(child, names, depth + 1, lines)
    return lines


def build_all(chain_rows, similar_rows):
    """({(slug, id): (tree id, narrations, books)}, [tree bytes by id - 1], [tree roots]) over the shelf."""
    index, trees, roots, ids = {}, [], [], {}
    for slug in SLUGS:
        shelf = Hadith(slug)
        for row in shelf.rows:
            key = (slug, row.idInBook)
            family = [key] + [(s, i) for s, i, _ in similar_rows.get(key, [])]
            members = [m for m in family if m in chain_rows]
            if len(members) < 2:
                continue
            root = build_tree(members, chain_rows)
            payload = bytes(serialize(root))
            tree_id = ids.get(payload)
            if tree_id is None:
                tree_id = ids[payload] = len(trees) + 1
                trees.append(payload)
                roots.append(root)
            index[key] = (tree_id, len(members), len({m[0] for m in members}))
    return index, trees, roots


# MARK: - The hadiths with the most chains

def substance(raw, parsed):
    """The words of a row's own text that say something: what follows its chain (the whole row when
    the app draws no chain for it) without the opening words, the honorifics and the pointing words."""
    start = 0
    if parsed:
        nodes = [node for layer in parsed['shared'] for node in layer]
        nodes += [node for layers in parsed['branches'] for layer in layers for node in layer]
        start = max((node.last for node in nodes), default=-1) + 1
    words = [similar.fold(token) for token in raw[start:]]
    return [w for w in words if w and w not in similar.LEAD_IN and w not in similar.NOISE and w not in similar.DROP
            and w not in POINTER]


def rank(index, chain_rows, similar_rows):
    """({(slug, id): chains}, the shelf's rows with the most chains, {slug: that book's}).

    The count and the two rules are the header's. The order is by chains, then by the books and the
    narrations of the row's tree (the numbers the app holds, so it sorts any list of its own the same
    way), then the shelf's order."""
    pointing, english = set(), {}
    for slug in SLUGS:
        shelf = Hadith(slug)
        for position, row in enumerate(shelf.rows):
            key = (slug, row.idInBook)
            found = chain_rows.get(key)
            if found is None and key not in index:
                continue
            item = shelf.item(position)
            english[key] = bool(item.text.strip())
            if len(substance(found[1] if found else item.arabic.split(), found[0] if found else None)) < 2:
                pointing.add(key)

    signatures = {}

    def signature(key):
        if key not in signatures:
            parsed, _, keys = chain_rows[key]
            book = SLUGS.index(key[0])
            signatures[key] = (book, frozenset(tuple(path_keys(path, book, keys)) for path in paths(parsed)))
        return signatures[key]

    families = {}

    def family(key):
        if key not in families:
            members = [key] if key in chain_rows else []
            for slug, id_in_book, tier in similar_rows.get(key, []):
                member = (slug, id_in_book)
                if member not in chain_rows or member in pointing:
                    continue
                if tier == similar.TIER_SIMILAR and slug == key[0] == 'tirmidhi':
                    continue
                members.append(member)
            families[key] = frozenset(members)
        return families[key]

    counts = {key: 0 if key in pointing else len({signature(member) for member in family(key)}) for key in index}

    def order(key):
        return (-counts[key], -index[key][2], -index[key][1], SLUGS.index(key[0]), key[1])

    def listed(keys, translated):
        taken, chosen, out = set(), set(), []
        for key in sorted(keys, key=order):
            if counts[key] < MIN_RANKED:
                break
            members = family(key)
            if key in taken or 2 * len(members & taken) >= len(members):
                taken |= members
                continue
            pick = key
            if translated and not english[key]:
                # The same hadith in a book the app has in English, when its own count is as good
                # as this one's to within a tenth: the row a reader of English can read.
                close = [m for m in members if m in index and english.get(m) and 10 * counts[m] >= 9 * counts[key]
                         and counts[m] >= MIN_RANKED]
                if close:
                    pick = min(close, key=order)
            taken |= members | family(pick) | {key, pick}
            # Two rows of one hadith can both be sent to the same translated row: it is listed once.
            if pick not in chosen:
                chosen.add(pick)
                out.append(pick)
        return sorted(out, key=order)

    shelf_list = listed(index, True)
    books = {slug: listed([key for key in index if key[0] == slug], False) for slug in SLUGS}
    return counts, shelf_list, books, len(pointing)


# MARK: - The pack

def write_pack(index, trees, counts, shelf_list, books):
    """HadithIsnadTrees.qpk (QuranPackContainer, QuranPack.swift):

      header (48), block table (16 per block); records = blocks, units = rows with a tree
      eager (LZFSE)   u32 books, then per book: string slug, u32 rows with a tree; u32 rows, u32 trees,
                      u32 shard, u32 shards
      block 0..B-1    book n's rows: a row block by idInBook, a row's payload varint tree id,
                      varint narrations in the tree, varint books in it, varint chains (`rank`)
      block B..       the trees, SHARD to a block by tree id (1-based): a row block, a row's payload
                      the tree in preorder (`serialize`)
      the last block  the rows with the most chains, most first: a row block of B + 1 rows, row 0 the
                      whole shelf's (u8 book, varint idInBook each), row n + 1 book n's (varint idInBook)

    The eager section ends with one more u32 after the shards: how many rows the shelf's list holds.
    Then reads the file back as the app will and checks every row and tree."""
    eager = bytearray(struct.pack('<I', len(SLUGS)))
    blocks = []
    for slug in SLUGS:
        rows = [(i, similar.varint(t) + similar.varint(n) + similar.varint(b) + similar.varint(counts[(s, i)]))
                for (s, i), (t, n, b) in index.items() if s == slug]
        blocks.append(chains.row_block(rows))
        data = slug.encode('utf-8')
        eager += struct.pack('<I', len(data)) + data + struct.pack('<I', len(rows))
    shards = (len(trees) + SHARD - 1) // SHARD
    eager += struct.pack('<IIIII', len(index), len(trees), SHARD, shards, len(shelf_list))
    for shard in range(shards):
        members = trees[shard * SHARD:(shard + 1) * SHARD]
        blocks.append(chains.row_block([(shard * SHARD + n + 1, payload) for n, payload in enumerate(members)]))
    blocks.append(chains.row_block(ranking_rows(shelf_list, books)))
    chains.write_container(OUT, eager, blocks, len(blocks), len(index))
    verify_pack(index, trees, counts, shelf_list, books)
    return sum(len(b) for b in blocks)


def ranking_rows(shelf_list, books):
    rows = [(0, b''.join(bytes([SLUGS.index(slug)]) + similar.varint(i) for slug, i in shelf_list))]
    for n, slug in enumerate(SLUGS):
        rows.append((n + 1, b''.join(similar.varint(i) for _, i in books[slug])))
    return rows


def verify_pack(index, trees, counts, shelf_list, books):
    eager, blocks, fields = chains.read_container(OUT)
    assert fields[6] == len(blocks) and fields[7] == len(index)
    pos = 4
    assert struct.unpack_from('<I', eager, 0)[0] == len(SLUGS)
    for slug in SLUGS:
        length = struct.unpack_from('<I', eager, pos)[0]
        assert eager[pos + 4:pos + 4 + length].decode('utf-8') == slug
        pos += 4 + length
        assert struct.unpack_from('<I', eager, pos)[0] == sum(1 for s, _ in index if s == slug), slug
        pos += 4
    rows, count, shard, shards, ranked = struct.unpack_from('<IIIII', eager, pos)
    assert pos + 20 == len(eager) and rows == len(index) and count == len(trees) and shard == SHARD
    assert ranked == len(shelf_list) and len(blocks) == len(SLUGS) + shards + 1
    for book, slug in enumerate(SLUGS):
        expected = sorted((i, v) for (s, i), v in index.items() if s == slug)
        found = chains.rows_of(blocks[book], len(expected))
        assert [i for i, _ in found] == [i for i, _ in expected], slug
        for (id_in_book, payload), (_, (tree_id, narrations, in_books)) in zip(found, expected):
            at = 0
            values = []
            for _ in range(4):
                value, at = similar.read_varint(payload, at)
                values.append(value)
            assert at == len(payload) and values == [tree_id, narrations, in_books, counts[(slug, id_in_book)]], slug
    lists = chains.rows_of(blocks[-1], len(SLUGS) + 1)
    assert [row_id for row_id, _ in lists] == list(range(len(SLUGS) + 1))
    at, found = 0, []
    while at < len(lists[0][1]):
        book = lists[0][1][at]
        id_in_book, at = similar.read_varint(lists[0][1], at + 1)
        found.append((SLUGS[book], id_in_book))
    assert found == shelf_list
    for n, slug in enumerate(SLUGS):
        at, found = 0, []
        while at < len(lists[n + 1][1]):
            id_in_book, at = similar.read_varint(lists[n + 1][1], at)
            found.append((slug, id_in_book))
        assert found == books[slug], slug
    for shard_index in range(shards):
        members = trees[shard_index * SHARD:(shard_index + 1) * SHARD]
        for (row_id, payload), (n, expected) in zip(chains.rows_of(blocks[len(SLUGS) + shard_index], len(members)), enumerate(members)):
            assert row_id == shard_index * SHARD + n + 1 and payload == expected


def write_samples(index, roots, names, counts, shelf_list, books):
    lines = ['// GENERATED by Scripts/build_isnad_trees.py: do not edit. A few rows\' trees of narrators exactly',
             '// as HadithIsnadTrees.qpk holds them (HadithIsnadTreesTests): the tree in preorder, one line per',
             '// node, "depth:root", "depth:narrator ids joined by +[^ raised]:name" (0 is a relation, with its text), or',
             '// "depth:book:idInBook[^ raised],...".',
             '', 'enum HadithIsnadTreeSamples {',
             '    struct Sample { let slug: String; let idInBook: Int; let tree: Int; let narrations: Int; let books: Int; let chains: Int; let outline: [String] }',
             f'    static let books = [{", ".join(json.dumps(s) for s in SLUGS)}]',
             f'    static let rowCount = {len(index)}',
             f'    static let treeCount = {len(roots)}',
             f'    static let shard = {SHARD}',
             '    /// The rows with the most chains: how many the shelf\'s list holds, its first rows with their',
             '    /// chains, and how many each book\'s own list holds.',
             f'    static let rankedCount = {len(shelf_list)}',
             '    static let mostChains: [(slug: String, idInBook: Int, chains: Int)] = ['
             + ', '.join(f'("{slug}", {i}, {counts[(slug, i)]})' for slug, i in shelf_list[:12]) + ']',
             '    static let rankedInBook: [String: Int] = ['
             + ', '.join(f'"{slug}": {len(books[slug])}' for slug in SLUGS) + ']',
             '    /// Rows whose own text only points at another narration: they count no chains.',
             '    static let pointing: [(slug: String, idInBook: Int)] = [("ahmed", 12820), ("ahmed", 1701), ("bukhari", 1162)]',
             '    static let all: [Sample] = [']
    for slug, id_in_book in SAMPLE_ROWS:
        found = index.get((slug, id_in_book))
        assert found, f'{slug}:{id_in_book} has no tree'
        tree_id, narrations, in_books = found
        text = ', '.join(json.dumps(line, ensure_ascii=False) for line in outline(roots[tree_id - 1], names))
        lines.append(f'        Sample(slug: "{slug}", idInBook: {id_in_book}, tree: {tree_id}, narrations: {narrations}, '
                     f'books: {in_books}, chains: {counts[(slug, id_in_book)]}, outline: [{text}]),')
    lines += ['    ]', '}', '']
    SAMPLES.write_text('\n'.join(lines), encoding='utf-8')


def main():
    started = time.time()
    chain_rows, compilers = read_chains()
    similar_rows = read_similar()
    names = read_names()
    shelf_links(chain_rows)
    print(f'{len(chain_rows)} chains, {len(similar_rows)} rows with similar narrations, {len(names)} narrators '
          f'read in {time.time() - started:.0f} s')
    index, trees, roots = build_all(chain_rows, similar_rows)
    leaves = Counter()
    for (slug, _), (tree_id, _, _) in index.items():
        leaves[min(roots[tree_id - 1].leaves, 100) // 10 * 10] += 1
    raw = sum(len(t) for t in trees)
    biggest = max(roots, key=lambda r: r.leaves)
    joined = Counter()
    def walk(node):
        if node.kind == KIND_NARRATOR and node.ids:
            joined[min(len(node.ids), 4)] += 1
        for child in node.children if isinstance(node.children, list) else node.children.values():
            if child.kind != KIND_LEAF:
                walk(child)
    for root in roots:
        walk(root)
    print('narrator nodes by names joined: ' + ' '.join(f'{k}={v}' for k, v in sorted(joined.items())))
    print(f'{len(index)} rows with a tree, {len(trees)} distinct trees ({raw} bytes), the largest with '
          f'{biggest.leaves} roads; rows by roads: ' + ' '.join(f'{k}+={v}' for k, v in sorted(leaves.items())))
    per_book = Counter(slug for slug, _ in index)
    print('   ' + ' '.join(f'{slug}={per_book[slug]}' for slug in SLUGS))
    counts, shelf_list, books, pointing = rank(index, chain_rows, similar_rows)
    spread = Counter(min(counts[key], 40) // 5 * 5 for key in shelf_list)
    print(f'most chains: {len(shelf_list)} hadiths with {MIN_RANKED} chains or more on the shelf\'s list ('
          + ' '.join(f'{k}+={v}' for k, v in sorted(spread.items())) + f'), {pointing} rows only point at another; by book: '
          + ' '.join(f'{slug}={len(books[slug])}' for slug in SLUGS))
    if '--ranking' in sys.argv:
        shelves = {}
        for slug, id_in_book in shelf_list[:int(sys.argv[sys.argv.index('--ranking') + 1])]:
            item = shelves.setdefault(slug, Hadith(slug)).find_id(id_in_book)
            tree_id, narrations, in_books = index[(slug, id_in_book)]
            print(f'   {counts[(slug, id_in_book)]:3} chains, {narrations:3} narrations, {in_books:2} books  {slug}:{id_in_book}  '
                  + (item.text or item.arabic[-80:])[:90].replace('\n', ' '))
        return
    if '--inspect' in sys.argv:
        for target in sys.argv[sys.argv.index('--inspect') + 1:]:
            slug, number = target.split(':')
            found = index.get((slug, int(number)))
            if not found:
                print(f'{target}: no tree')
                continue
            tree_id, narrations, in_books = found
            print(f'== {target}: tree {tree_id}, {narrations} narrations in {in_books} books, {roots[tree_id - 1].leaves} roads, '
                  f'{counts[(slug, int(number))]} chains')
            for line in outline(roots[tree_id - 1], names):
                depth, _, rest = line.partition(':')
                print('   ' + '  ' * int(depth) + rest)
        return
    if '--stats' in sys.argv:
        return
    raw = write_pack(index, trees, counts, shelf_list, books)
    print(f'{OUT.relative_to(ROOT)}: {len(index)} rows, {len(trees)} trees, {raw} -> {OUT.stat().st_size} bytes, '
          f'read back and verified')
    write_samples(index, roots, names, counts, shelf_list, books)
    print(f'{SAMPLES.relative_to(ROOT)} written ({time.time() - started:.0f} s)')


if __name__ == '__main__':
    main()
