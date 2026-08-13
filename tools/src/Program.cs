using System;
using System.Collections.Generic;
using DatReaderWriter;
using DatReaderWriter.Options;
using DatReaderWriter.Lib.IO.DatBTree;

class DatForensics {
    static int violations = 0;
    static DatBTreeReaderWriter tree;

    static void Main(string[] args) {
        if (args.Length < 2) { Console.WriteLine("usage: DatForensics <dat> <idHex> [idHex...]  |  DatForensics fixiter <dat> <idHex> <iter>"); return; }
        if (args[0] == "fixiter") {
            var wdb = new DatDatabase(o => { o.FilePath = args[1]; o.AccessType = DatAccessType.ReadWrite; }, null);
            uint fid = Convert.ToUInt32(args[2], 16);
            int newIter = int.Parse(args[3]);
            DatBTreeFile fe;
            if (!wdb.Tree.TryGetFile(fid, out fe)) { Console.WriteLine("id not found"); return; }
            byte[] data;
            if (!wdb.TryGetFileBytes(fid, out data, false)) { Console.WriteLine("byte read failed"); return; }
            Console.WriteLine($"before: Iter={fe.Iteration} RawDate={fe.RawDate} Size={fe.Size}");
            fe.Iteration = newIter;
            fe.RawDate = 1117237542; // retail-era date, belt and suspenders
            if (wdb.TryWriteFileBytes(fid, data, data.Length, fe)) {
                DatBTreeFile chk; wdb.Tree.TryGetFile(fid, out chk);
                Console.WriteLine($"after:  Iter={chk.Iteration} RawDate={chk.RawDate} Size={chk.Size}");
                Console.WriteLine("OK - entry metadata rewritten, payload unchanged");
            } else Console.WriteLine("WRITE FAILED");
            return;
        }
        if (args[0] == "fixversion") {
            var vdb = new DatDatabase(o => { o.FilePath = args[1]; o.AccessType = DatAccessType.ReadWrite; }, null);
            uint vid = Convert.ToUInt32(args[2], 16);
            int newVer = int.Parse(args[3]);
            DatBTreeFile ve;
            if (!vdb.Tree.TryGetFile(vid, out ve)) { Console.WriteLine("id not found"); return; }
            byte[] vdata;
            if (!vdb.TryGetFileBytes(vid, out vdata, false)) { Console.WriteLine("byte read failed"); return; }
            Console.WriteLine($"before: Version={ve.Version} Iter={ve.Iteration}");
            var vt = ve.GetType().GetProperty("Version");
            object boxed = ve;
            vt.SetValue(boxed, Convert.ChangeType(newVer, vt.PropertyType));
            ve = (DatBTreeFile)boxed;
            if (vdb.TryWriteFileBytes(vid, vdata, vdata.Length, ve)) {
                DatBTreeFile vchk; vdb.Tree.TryGetFile(vid, out vchk);
                Console.WriteLine($"after:  Version={vchk.Version} Iter={vchk.Iteration}");
                Console.WriteLine("OK");
            } else Console.WriteLine("WRITE FAILED");
            return;
        }
        if (args[0] == "freechain") {
            var rdb = new DatDatabase(o => { o.FilePath = args[1]; o.AccessType = DatAccessType.Read; }, null);
            var alloc = rdb.BlockAllocator;
            var readBlock = alloc.GetType().GetMethod("ReadBlock", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            var readBytes = alloc.GetType().GetMethod("ReadBytes", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            Func<int,int> nextPtr = (off) => {
                byte[] b4 = new byte[4];
                readBytes.Invoke(alloc, new object[]{ b4, 0, off, 4 });
                return BitConverter.ToInt32(b4, 0);
            };
            // walk free chain
            var free = new HashSet<int>();
            int cur = rdb.Header.FirstFreeBlock;
            int guard = 0;
            while (cur != 0 && guard++ < 500000) {
                if (!free.Add(cur)) { Console.WriteLine($"FREE CHAIN LOOP at 0x{cur:X}!"); break; }
                cur = nextPtr(cur) & 0x7FFFFFFF;
            }
            Console.WriteLine($"free chain: {free.Count} blocks (header says {rdb.Header.FreeBlockCount})");
            // walk data chains of the ids given (args[2..]) plus full-tree overlap scan flag "all"
            var ids = new List<uint>();
            for (int k = 2; k < args.Length; k++) if (args[k] != "all") ids.Add(Convert.ToUInt32(args[k], 16));
            bool scanAll = Array.IndexOf(args, "all") >= 0;
            int blockSize = (int)rdb.Header.BlockSize;
            Func<DatBTreeFile, List<int>> chainOf = (fe) => {
                var lst = new List<int>();
                int c = fe.Offset; int need = (int)fe.Size; int g2 = 0;
                while (c != 0 && need > 0 && g2++ < 100000) {
                    lst.Add(c);
                    int np = nextPtr(c);
                    need -= (blockSize - 4);
                    c = np & 0x7FFFFFFF;
                }
                return lst;
            };
            foreach (var id in ids) {
                DatBTreeFile fe;
                if (!rdb.Tree.TryGetFile(id, out fe)) { Console.WriteLine($"0x{id:X8}: not found"); continue; }
                var ch = chainOf(fe);
                var overlap = ch.FindAll(b => free.Contains(b));
                Console.WriteLine($"0x{id:X8}: {ch.Count} data blocks @0x{fe.Offset:X}  OVERLAP WITH FREE CHAIN: {overlap.Count}" + (overlap.Count>0 ? "  *** CORRUPTION ***" : ""));
                foreach (var b in overlap) Console.WriteLine($"    shared block: 0x{b:X}");
            }
            if (scanAll) {
                int filesWithOverlap = 0, totalChecked = 0;
                foreach (var fe in rdb.Tree) {
                    totalChecked++;
                    var ch = chainOf(fe);
                    int ov = ch.FindAll(b => free.Contains(b)).Count;
                    if (ov > 0) { filesWithOverlap++; Console.WriteLine($"  OVERLAP: 0x{fe.Id:X8} ({ov} blocks)"); }
                }
                Console.WriteLine($"full scan: {totalChecked} files, {filesWithOverlap} with free-chain overlap");
            }
            return;
        }
        var db = new DatDatabase(o => { o.FilePath = args[0]; o.AccessType = DatAccessType.Read; }, null);
        tree = db.Tree;
        Console.WriteLine($"HEADER: Magic=0x{db.Header.Magic:X} BlockSize={db.Header.BlockSize} RootBlock=0x{db.Header.RootBlock:X}");
        Console.WriteLine($"        FreeBlocks={db.Header.FreeBlockCount} FirstFree=0x{db.Header.FirstFreeBlock:X} LastFree=0x{db.Header.LastFreeBlock:X}");
        Console.WriteLine($"        Degree={tree.Degree} MaxItems={tree.MaxItems}");

        int nodes = 0, files = 0, depthMax = 0;
        Audit(tree.Root, 0, 0, uint.MaxValue, ref nodes, ref files, ref depthMax);
        Console.WriteLine($"\nTREE AUDIT: {nodes} nodes, {files} file entries, depth {depthMax}, VIOLATIONS: {violations}");

        for (int ai = 1; ai < args.Length; ai++) {
            uint id = Convert.ToUInt32(args[ai], 16);
            Console.WriteLine($"\n--- 0x{id:X8} ---");
            StrictDescent(id);
            DatBTreeFile f;
            if (tree.TryGetFile(id, out f)) {
                Console.WriteLine($"  ENTRY: Flags={f.Flags} Version={f.Version} Offset=0x{f.Offset:X} Size={f.Size} Iter={f.Iteration} RawDate={f.RawDate}");
                byte[] buf;
                if (db.TryGetFileBytes(id, out buf, false)) {
                    int n = Math.Min(24, buf.Length);
                    var head = BitConverter.ToString(buf, 0, n).Replace("-", " ");
                    uint embedded = buf.Length >= 4 ? BitConverter.ToUInt32(buf, 0) : 0;
                    Console.WriteLine($"  BYTES: total={buf.Length} head: {head}");
                    Console.WriteLine($"  EMBEDDED-ID: 0x{embedded:X8} {(embedded == id ? "MATCHES" : "*** MISMATCH ***")}");
                } else Console.WriteLine("  BYTES: TryGetFileBytes FAILED");
            } else Console.WriteLine("  ENTRY: NOT FOUND by library");
        }
    }

    static DatBTreeNode GetNode(int offset) {
        try {
            var ms = typeof(DatBTreeReaderWriter).GetMethods(System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
            foreach (var m in ms) {
                if (m.Name != "GetNode" && m.Name != "TryGetNode") continue;
                var pars = m.GetParameters();
                if (pars.Length == 1) { return m.Invoke(tree, new object[]{ Convert.ChangeType(offset, pars[0].ParameterType) }) as DatBTreeNode; }
                if (pars.Length == 2) {
                    object[] a = new object[]{ Convert.ChangeType(offset, pars[0].ParameterType), null };
                    var r = m.Invoke(tree, a);
                    if (r is bool ok) { return ok ? a[1] as DatBTreeNode : null; }
                    return r as DatBTreeNode ?? a[1] as DatBTreeNode;
                }
            }
        } catch (Exception e) { Console.WriteLine($"  [node-read-error 0x{offset:X}: {e.InnerException?.Message ?? e.Message}]"); }
        return null;
    }

    static void Audit(DatBTreeNode node, int depth, uint lo, uint hi, ref int nodes, ref int files, ref int depthMax) {
        if (node == null) { Console.WriteLine("  [VIOLATION] null node in audit"); violations++; return; }
        nodes++; if (depth > depthMax) depthMax = depth;
        uint prev = lo;
        for (int i = 0; i < node.FileCount; i++) {
            files++;
            var id = node.Files[i].Id;
            if (id <= prev && prev != 0) { Console.WriteLine($"  [VIOLATION] node 0x{node.Offset:X} file[{i}] id 0x{id:X8} <= prev 0x{prev:X8}"); violations++; }
            if (id < lo || id > hi) { Console.WriteLine($"  [VIOLATION] node 0x{node.Offset:X} file[{i}] id 0x{id:X8} outside 0x{lo:X8}-0x{hi:X8}"); violations++; }
            prev = id;
        }
        if (!node.IsLeaf) {
            if (node.BranchCount != node.FileCount + 1) { Console.WriteLine($"  [VIOLATION] node 0x{node.Offset:X} branches={node.BranchCount} files={node.FileCount} (want files+1)"); violations++; }
            for (int b = 0; b < node.BranchCount; b++) {
                uint blo = b == 0 ? lo : node.Files[b-1].Id;
                uint bhi = b >= node.FileCount ? hi : node.Files[b].Id;
                var child = GetNode(node.Branches[b]);
                if (child == null) { Console.WriteLine($"  [VIOLATION] node 0x{node.Offset:X} branch[{b}] -> 0x{node.Branches[b]:X} UNREADABLE"); violations++; continue; }
                Audit(child, depth+1, blo, bhi, ref nodes, ref files, ref depthMax);
            }
        }
    }

    static void StrictDescent(uint id) {
        var node = tree.Root; int depth = 0;
        while (node != null) {
            int i = 0;
            while (i < node.FileCount && id > node.Files[i].Id) i++;
            if (i < node.FileCount && node.Files[i].Id == id) { Console.WriteLine($"  DESCENT: found at depth {depth}, node 0x{node.Offset:X}, index {i} (leaf={node.IsLeaf})"); return; }
            if (node.IsLeaf) { Console.WriteLine($"  DESCENT: NOT FOUND (leaf at depth {depth}, node 0x{node.Offset:X})"); return; }
            node = GetNode(node.Branches[i]); depth++;
        }
        Console.WriteLine("  DESCENT: broke - unreadable node");
    }
}
