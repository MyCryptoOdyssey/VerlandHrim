// DerethWatch Decal Plugin - live preview wall for AC multibox clients - in-game fleet vision toggle
// An eye medallion docked over the client window. Click: every AC client
// un-patches (UB Video Patch off) and a live DWM thumbnail strip opens.
// Click again: strip closes, fleet re-patches to near-zero cost.
// Build: run build.bat   Register: Decal > Add > Browse > FleetEyesDecal.dll
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using Decal.Adapter;

namespace DerethWatch
{
    [FriendlyName("DerethWatch")]
    public class PluginCore : PluginBase
    {
        static readonly string[] CMDS_ON  = { "/ub videopatch disable",
                                              "/ub opt set Plugin.VideoPatchFocus false" };
        static readonly string[] CMDS_OFF = { "/ub videopatch enable",
                                              "/ub opt set Plugin.VideoPatchFocus true" };
        internal static readonly uint WM_FE = Native.RegisterWindowMessage("DerethWatchToggleMsg");
        VirindiViewService.HudView view;
        VirindiViewService.Controls.HudCheckBox chk;
        VirindiViewService.Controls.HudCheckBox chkClientOnly;
        StripForm strip;
        Thread stripThread;
        CtlWindow ctl;
        bool eyes = false;
        bool syncing = false;
        int myPid = Process.GetCurrentProcess().Id;
        IntPtr myClientHwnd = IntPtr.Zero;

        protected override void Startup()
        {
            try
            {
                VirindiViewService.ViewProperties properties;
                VirindiViewService.ControlGroup controls;
                var parser = new VirindiViewService.XMLParsers.Decal3XMLParser();
                parser.ParseFromResource("DerethWatch.ViewXML.xml", out properties, out controls);
                view = new VirindiViewService.HudView(properties, controls);
                chk = (VirindiViewService.Controls.HudCheckBox)view["chkEye"];
                chk.Change += new EventHandler(Chk_Change);
                chkClientOnly = (VirindiViewService.Controls.HudCheckBox)view["chkClientOnly"];
                chkClientOnly.Checked = true;
                chkClientOnly.Change += new EventHandler(ChkClientOnly_Change);
                ctl = new CtlWindow(this);
                // cache OUR top-level client window once; used for chat delivery both ways
                foreach (var w in Native.AcWindows())
                {
                    uint wpid; Native.GetWindowThreadProcessId(w.Key, out wpid);
                    if (wpid == (uint)myPid) { myClientHwnd = w.Key; break; }
                }
                if (myClientHwnd == IntPtr.Zero) myClientHwnd = (IntPtr)Host.Decal.Hwnd;
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }
        protected override void Shutdown()
        {
            try
            {
                CloseStrip();
                if (chk != null) chk.Change -= new EventHandler(Chk_Change);
                if (view != null) { view.Dispose(); view = null; }
                if (ctl != null) { ctl.DestroyHandle(); ctl = null; }
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }
        void ChkClientOnly_Change(object sender, EventArgs e)
        {
            var s = strip;
            if (s != null) s.ClientOnly = chkClientOnly.Checked;
        }
        void CloseStrip()
        {
            var s = strip;
            var t = stripThread;
            if (s == null) { stripThread = null; return; }
            try
            {
                if (s.IsHandleCreated && !s.IsDisposed)
                {
                    s.BeginInvoke(new MethodInvoker(() =>
                    {
                        try { s.ForceClose(); } catch { }
                        try { Application.ExitThread(); } catch { }
                    }));
                }
            }
            catch (Exception ex) { Native.Log("CloseStrip EX: " + ex.Message); }
            // Wait for the STA thread to actually exit before letting a new strip start
            try { if (t != null && !t.Join(1500)) Native.Log("stripThread did not exit in 1500ms"); } catch { }
            strip = null;
            stripThread = null;
        }
        void Chk_Change(object sender, EventArgs e)
        {
            FeLog.W("Chk_Change fired, syncing=" + syncing + " chk.Checked=" + chk.Checked);
            if (syncing) return;
            bool want = chk.Checked;
            FeLog.W("  local OnRemote + broadcast, want=" + want);
            OnRemote(want, myPid);                                             // guaranteed local
            Native.PostMessage((IntPtr)0xFFFF, WM_FE, (IntPtr)(want ? 1 : 0), (IntPtr)myPid);   // bonus
        }
        internal void OnRemote(bool state, int initiatorPid)
        {
            try
            {
                eyes = state;
                if (chk != null) { syncing = true; chk.Checked = eyes; syncing = false; }
                CloseStrip();
                // EVERY instance types the commands into its own client window -
                // identical path to manual typing, which works on every UB build
                {
                    string[] cmds = eyes ? CMDS_ON : CMDS_OFF;
                    Native.Log("OnRemote state=" + eyes + " initiator=" + initiatorPid + " cmds=" + cmds.Length);
                    int i = 0;
                    foreach (string c in cmds)
                    {
                        Native.Log("fire[" + (++i) + "]: " + c);
                        try { Native.FireCommandLineText(c); Native.Log("  ok"); }
                        catch (Exception ex) { Native.Log("  EX: " + ex.Message); }
                    }
                }
                if (initiatorPid != myPid) return;      // only the initiator hosts the strip
                if (eyes)
                {
                    var wins = Native.AcWindows();
                    IntPtr hostHwnd = (IntPtr)Host.Decal.Hwnd;
                    bool clientOnly = (chkClientOnly == null) || chkClientOnly.Checked;
                    var stripReady = new System.Threading.ManualResetEventSlim(false);
                    stripThread = new Thread(() =>
                    {
                        strip = new StripForm(wins, hostHwnd);
                        strip.ClientOnly = clientOnly;
                        strip.HandleCreated += (s, e) => stripReady.Set();
                        strip.Show();
                        Application.Run();               // pump this thread's messages
                        try { strip.Dispose(); } catch { }
                        strip = null;
                    });
                    stripThread.SetApartmentState(ApartmentState.STA);
                    stripThread.IsBackground = true;
                    stripThread.Start();
                    stripReady.Wait(2000);
                }
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }
    }

    class CtlWindow : NativeWindow
    {
        PluginCore owner;
        public CtlWindow(PluginCore o) { owner = o; CreateHandle(new CreateParams()); }
        protected override void WndProc(ref System.Windows.Forms.Message m)
        {
            if ((uint)m.Msg == PluginCore.WM_FE)
                owner.OnRemote(m.WParam != IntPtr.Zero, m.LParam.ToInt32());
            base.WndProc(ref m);
        }
    }

    static class Native
    {
        [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
        public delegate bool EnumProc(IntPtr hWnd, IntPtr lp);
        [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
        [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
        [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
        [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
        [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
        [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
        [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
        [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
        public static void FocusWindow(IntPtr target)
        {
            BringWindowToTop(target);
            SetForegroundWindow(target);
        }
        [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern uint RegisterWindowMessage(string name);
        [DllImport("user32.dll")] public static extern IntPtr SetParent(IntPtr child, IntPtr parent);
        [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
        [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
        [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h, int i, int v);
        [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hgt, bool r);
        [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a, bool i, uint pid);
        [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        public static extern bool QueryFullProcessImageName(IntPtr h, int f, StringBuilder exe, ref int size);
        [DllImport("dwmapi.dll")] public static extern int DwmRegisterThumbnail(IntPtr dest, IntPtr src, out IntPtr thumb);
        public static void Log(string s) {
            try { Decal.Adapter.CoreManager.Current.Actions.AddChatText("[DW] " + s, 5); } catch { }
        }
        [DllImport("dwmapi.dll")] public static extern int DwmUnregisterThumbnail(IntPtr thumb);
        [DllImport("dwmapi.dll")] public static extern int DwmUpdateThumbnailProperties(IntPtr thumb, ref ThumbProps p);
        [StructLayout(LayoutKind.Sequential)]
        public struct ThumbProps
        {
            public int dwFlags; public RECT rcDestination; public RECT rcSource;
            public byte opacity; public bool fVisible; public bool fSourceClientAreaOnly;
        }
        [StructLayout(LayoutKind.Sequential)]
        public struct RECT { public int L, T, R, B; }
        public const uint WM_KEYDOWN = 0x100, WM_KEYUP = 0x101, WM_CHAR = 0x102;
        public const int VK_RETURN = 0x0D;

        public static List<KeyValuePair<IntPtr, string>> AcWindows()
        {
            var list = new List<KeyValuePair<IntPtr, string>>();
            EnumWindows((h, lp) =>
            {
                if (!IsWindowVisible(h)) return true;
                uint pid; GetWindowThreadProcessId(h, out pid);
                IntPtr p = OpenProcess(0x1000, false, pid);
                if (p != IntPtr.Zero)
                {
                    var sb = new StringBuilder(1024); int n = 1024;
                    if (QueryFullProcessImageName(p, 0, sb, ref n) &&
                        sb.ToString().ToLower().EndsWith("acclient.exe"))
                    {
                        var t = new StringBuilder(256);
                        GetWindowText(h, t, 256);
                        string title = t.ToString();
                        RECT wr; GetWindowRect(h, out wr);
                        bool ours = title.StartsWith("DerethWatch");
                        bool tiny = (wr.R - wr.L) < 300 || (wr.B - wr.T) < 200;
                        if (!ours && !tiny)
                            list.Add(new KeyValuePair<IntPtr, string>(h, title));
                    }
                    CloseHandle(p);
                }
                return true;
            }, IntPtr.Zero);
            return list;
        }

        static System.Reflection.MethodInfo _raiseCommandLineText;
        static object _coreManagerInstance;
        public static void FireCommandLineText(string text)
        {
            // Raise CoreManager.CommandLineText so plugin-registered handlers
            // (like UB's Core_CommandLineText) see the command. Uses reflection
            // to invoke the event's delegate field directly.
            try
            {
                if (_raiseCommandLineText == null)
                {
                    _coreManagerInstance = Decal.Adapter.CoreManager.Current;
                    var t = _coreManagerInstance.GetType();
                    // events are stored as private delegate fields with the same name
                    var fld = t.GetField("myChatParserIntercept", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
                    if (fld == null && t.BaseType != null)
                        fld = t.BaseType.GetField("myChatParserIntercept", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
                    if (fld == null)
                    {
                        foreach (var f in t.GetFields(System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Public))
                            if (f.FieldType.Name.Contains("EventHandler") && f.Name == "myChatParserIntercept") { fld = f; break; }
                    }
                    if (fld != null)
                    {
                        var del = fld.GetValue(_coreManagerInstance) as Delegate;
                        if (del != null) _raiseCommandLineText = del.GetType().GetMethod("Invoke");
                    }
                }
                var argsType = typeof(Decal.Adapter.ChatParserInterceptEventArgs);
                var ctor = argsType.GetConstructor(
                    System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Public,
                    null, new[] { typeof(string), typeof(bool) }, null);
                var args = (Decal.Adapter.ChatParserInterceptEventArgs)ctor.Invoke(new object[] { text, false });
                var t2 = _coreManagerInstance.GetType();
                var f2 = t2.GetField("myChatParserIntercept", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
                if (f2 == null && t2.BaseType != null)
                    f2 = t2.BaseType.GetField("myChatParserIntercept", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
                if (f2 != null)
                {
                    var delegateNow = f2.GetValue(_coreManagerInstance) as Delegate;
                    if (delegateNow != null)
                        delegateNow.DynamicInvoke(_coreManagerInstance, args);
                }
            }
            catch (Exception ex) { Log("FireCommandLineText EX: " + ex.Message); }
        }
        public static void SendChat(IntPtr h, string text)
        {
            PostMessage(h, WM_KEYDOWN, (IntPtr)VK_RETURN, IntPtr.Zero);
            PostMessage(h, WM_KEYUP, (IntPtr)VK_RETURN, IntPtr.Zero);
            Thread.Sleep(140);
            foreach (char c in text)
            { PostMessage(h, WM_CHAR, (IntPtr)c, IntPtr.Zero); Thread.Sleep(5); }
            Thread.Sleep(60);
            PostMessage(h, WM_KEYDOWN, (IntPtr)VK_RETURN, IntPtr.Zero);
            PostMessage(h, WM_KEYUP, (IntPtr)VK_RETURN, IntPtr.Zero);
        }
    }

    static class FeLog
    {
        static readonly object lk = new object();
        static readonly string path = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "DerethWatch.log");
        public static void W(string msg)
        {
            try { lock (lk) System.IO.File.AppendAllText(path,
                DateTime.Now.ToString("HH:mm:ss.fff") + " pid=" + Process.GetCurrentProcess().Id + " " + msg + "\r\n"); } catch { }
        }
    }

    // ---------- the preview strip ----------
    public class StripForm : Form
    {
        List<IntPtr> thumbs = new List<IntPtr>();
        List<KeyValuePair<Rectangle, IntPtr>> slices = new List<KeyValuePair<Rectangle, IntPtr>>();
        List<KeyValuePair<Rectangle, IntPtr>> dests = new List<KeyValuePair<Rectangle, IntPtr>>();
        int active = -1;
        public bool ClientOnly = true;
        public void ForceClose()
        {
            Native.Log("ForceClose enter, thumbs=" + thumbs.Count);
            // 1) stop the timer so it never re-registers or re-invalidates
            try { if (watch != null) { watch.Stop(); watch.Dispose(); watch = null; Native.Log("  watch stopped"); } } catch (Exception ex) { Native.Log("  watch EX: " + ex.Message); }
            // 2) hide the host window FIRST so DWM stops compositing our thumbnails
            try { Hide(); Native.Log("  Hide() done"); } catch (Exception ex) { Native.Log("  Hide EX: " + ex.Message); }
            // 3) hide each thumbnail explicitly (fVisible=false) before unregistering
            try
            {
                foreach (var t in thumbs)
                {
                    var p = new Native.ThumbProps();
                    p.dwFlags = 0x8;   // TNP_VISIBLE only
                    p.fVisible = false;
                    try { Native.DwmUpdateThumbnailProperties(t, ref p); } catch { }
                    try { Native.DwmUnregisterThumbnail(t); } catch { }
                }
                thumbs.Clear();
                Native.Log("  thumbs hidden+freed");
            }
            catch (Exception ex) { Native.Log("  thumb EX: " + ex.Message); }
            // 4) close and dispose the host, ending its message pump
            try { Close(); Native.Log("  Close() done"); } catch (Exception ex) { Native.Log("  Close EX: " + ex.Message); }
            try { Dispose(); Native.Log("  Dispose() done"); } catch (Exception ex) { Native.Log("  Dispose EX: " + ex.Message); }
            try { Application.ExitThread(); Native.Log("  ExitThread called"); } catch (Exception ex) { Native.Log("  ExitThread EX: " + ex.Message); }
        }
        System.Collections.Generic.HashSet<IntPtr> clientSet = new System.Collections.Generic.HashSet<IntPtr>();
        IntPtr host;
        System.Windows.Forms.Timer watch;
        public StripForm(List<KeyValuePair<IntPtr, string>> wins, IntPtr hostHwnd)
        {
            host = hostHwnd;
            watch = new System.Windows.Forms.Timer(); watch.Interval = 150;
            watch.Tick += (s, e) =>
            {
                try
                {
                    IntPtr fg = Native.GetForegroundWindow();
                    bool show = !Native.IsIconic(host);
                    if (ClientOnly) show = show && clientSet.Contains(fg);
                    Visible = show;
                    int a = -1;
                    for (int i = 0; i < dests.Count; i++) if (dests[i].Value == fg) a = i;
                    if (a != active) { active = a; Invalidate(); }
                }
                catch { }
            };
            watch.Start();
            Text = "DerethWatchStrip";
            FormBorderStyle = FormBorderStyle.None; ShowInTaskbar = false;
            StartPosition = FormStartPosition.Manual; BackColor = Color.FromArgb(16, 16, 16);
            DoubleBuffered = true;
            var scr = Screen.PrimaryScreen.WorkingArea;
            int n = Math.Max(1, wins.Count);
            int tw = Math.Min(380, (scr.Width - 60 - 8 * (n - 1)) / n);
            int th = tw * 9 / 16;
            int W = tw * n + 8 * (n - 1) + 16, H = th + 34;
            Bounds = new Rectangle(scr.Left + (scr.Width - W) / 2, scr.Bottom - H - 10, W, H);
            Load += (s, e) =>
            {
                foreach (var w in wins) clientSet.Add(w.Key);
                for (int i = 0; i < wins.Count; i++)
                {
                    int x0 = 8 + i * (tw + 8);
                    var lbl = new Label
                    {
                        Text = CharName(wins[i].Value), ForeColor = Color.FromArgb(185, 163, 90),
                        BackColor = BackColor, Font = new Font("Segoe UI", 8, FontStyle.Bold),
                        Bounds = new Rectangle(x0, 2, tw, 14), TextAlign = ContentAlignment.MiddleCenter
                    };
                    Controls.Add(lbl);
                    IntPtr tid;
                    if (Native.DwmRegisterThumbnail(Handle, wins[i].Key, out tid) == 0)
                    {
                        var p = new Native.ThumbProps
                        {
                            dwFlags = 0x1 | 0x8 | 0x10,
                            rcDestination = new Native.RECT { L = x0, T = 18, R = x0 + tw, B = 18 + th },
                            fVisible = true, fSourceClientAreaOnly = true
                        };
                        Native.DwmUpdateThumbnailProperties(tid, ref p);
                        thumbs.Add(tid);
                        dests.Add(new KeyValuePair<Rectangle, IntPtr>(new Rectangle(x0, 18, tw, th), wins[i].Key));
                    }
                    slices.Add(new KeyValuePair<Rectangle, IntPtr>(new Rectangle(x0, 0, tw, H), wins[i].Key));
                }
            };
            MouseClick += (s, e) =>
            {
                foreach (var sl in slices)
                    if (sl.Key.Contains(e.Location))
                    {
                        if (Native.IsIconic(sl.Value)) Native.ShowWindow(sl.Value, 9);  // SW_RESTORE
                        Native.FocusWindow(sl.Value);
                        return;
                    }
            };
            FormClosed += (s, e) => { if (watch != null) watch.Stop(); foreach (var t in thumbs) Native.DwmUnregisterThumbnail(t); };
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            if (active >= 0 && active < dests.Count)
                using (var gold = new Pen(Color.FromArgb(201, 171, 95), 3))
                {
                    var r = dests[active].Key; r.Inflate(2, 2);
                    e.Graphics.DrawRectangle(gold, r);
                }
        }
        protected override bool ShowWithoutActivation { get { return true; } }
        protected override CreateParams CreateParams
        {
            get
            {
                var cp = base.CreateParams;
                cp.ExStyle |= 0x08000008;   // WS_EX_NOACTIVATE | WS_EX_TOPMOST
                return cp;
            }
        }
        static string CharName(string title)
        {
            var parts = title.Split('-');
            return parts.Length > 0 ? parts[parts.Length - 1].Trim() : title;
        }
    }
}
