// LeakWatch - AC client memory monitor & lag-death guardian
// The 32-bit client (LAA) has a hard 4GB address-space ceiling and leaks
// toward it as you play. LeakWatch shows live usage color-coded on the
// Virindi bar, warns in chat at 75% and 90%, and (optional) auto-recalls
// to lifestone at 95% before the engine starves.
// Build: build.bat   Register: Decal > Add > Browse > LeakWatch.dll
using System;
using System.Diagnostics;
using System.Drawing;
using Decal.Adapter;

namespace LeakWatch
{
    [FriendlyName("LeakWatch")]
    public class PluginCore : PluginBase
    {
        // Effective ceiling: the practical wall. Fragmentation degrades the
        // engine well before the hard 4GB address-space limit, so 100% here
        // means "you are done", not "theoretical maximum".
        const double CEILING = 3.8 * 1073741824.0;    // 3.8 GB effective
        const double YELLOW = 0.70, RED = 0.85, PANIC = 0.90;

        VirindiViewService.HudView view;
        VirindiViewService.Controls.HudStaticText lbl;
        VirindiViewService.Controls.HudCheckBox chkRecall;
        VirindiViewService.Controls.HudCheckBox chkLogout;
        System.Windows.Forms.Timer timer;
        int warned = 0;                                // 0 none, 1 yellow, 2 red
        DateTime lastRecall = DateTime.MinValue;
        DateTime pendingLogout = DateTime.MinValue;

        protected override void Startup()
        {
            try
            {
                VirindiViewService.ViewProperties properties;
                VirindiViewService.ControlGroup controls;
                var parser = new VirindiViewService.XMLParsers.Decal3XMLParser();
                parser.ParseFromResource("LeakWatch.ViewXML.xml", out properties, out controls);
                view = new VirindiViewService.HudView(properties, controls);
                lbl = (VirindiViewService.Controls.HudStaticText)view["lblMem"];
                chkRecall = (VirindiViewService.Controls.HudCheckBox)view["chkRecall"];
                chkRecall.Checked = true;
                chkLogout = (VirindiViewService.Controls.HudCheckBox)view["chkLogout"];
                chkLogout.Checked = false;   // "Recall & Logout" - implies recall first

                timer = new System.Windows.Forms.Timer();
                timer.Interval = 5000;
                timer.Tick += Timer_Tick;
                timer.Start();
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }

        protected override void Shutdown()
        {
            try
            {
                if (timer != null) { timer.Stop(); timer.Dispose(); timer = null; }
                if (view != null) { view.Dispose(); view = null; }
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }

        void Timer_Tick(object sender, EventArgs e)
        {
            try
            {
                double used = Process.GetCurrentProcess().VirtualMemorySize64;
                double pct = used / CEILING;

                if (lbl != null)
                {
                    lbl.Text = string.Format("Memory {0:0}%", Math.Min(pct, 1.0) * 100);
                    try
                    {
                        if (pct < YELLOW) lbl.TextColor = Color.FromArgb(120, 220, 120);
                        else if (pct < RED) lbl.TextColor = Color.FromArgb(235, 210, 90);
                        else lbl.TextColor = Color.FromArgb(240, 90, 90);
                    }
                    catch { }
                }

                // chat warnings, latched per band so they fire once per crossing
                if (pct >= RED && warned < 2)
                {
                    warned = 2;
                    Chat(string.Format("[LeakWatch] DANGER: memory {0:0}% - relog soon to avoid lag death.", pct * 100));
                }
                else if (pct >= YELLOW && warned < 1)
                {
                    warned = 1;
                    Chat(string.Format("[LeakWatch] Warning: memory {0:0}% - plan a relog.", pct * 100));
                }
                else if (pct < YELLOW && warned != 0)
                {
                    warned = 0;                        // fresh session / dropped back
                }

                // panic actions (once per 3 minutes max):
                // Auto-Recall = park at lifestone, stay logged in.
                // Recall & Logout = park, wait for the cast to finish, then log out
                // (logout is what actually frees the leaked memory).
                if (pct >= PANIC && (DateTime.Now - lastRecall).TotalSeconds > 180)
                    DoPanic(false);
                if (pendingLogout != DateTime.MinValue && DateTime.Now >= pendingLogout)
                {
                    pendingLogout = DateTime.MinValue;
                    Chat("[LeakWatch] Logging out to free memory.");
                    try { CoreManager.Current.Actions.Logout(); } catch { try { CoreManager.Current.Actions.InvokeChatParser("/logout"); } catch { } }
                }
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }

        void DoPanic(bool isTest)
        {
            string tag = isTest ? "[LeakWatch TEST] " : "[LeakWatch] CRITICAL: ";
            bool doRecall = chkRecall != null && chkRecall.Checked;
            bool doLogout = chkLogout != null && chkLogout.Checked;
            if (!doRecall && !doLogout)
            {
                if (isTest) Chat("[LeakWatch TEST] no action armed - check a box first.");
                return;
            }
            lastRecall = DateTime.Now;
            try { CoreManager.Current.Actions.InvokeChatParser("/vt opt set EnableCombat false"); } catch { }
            if (doRecall)
            {
                Chat(tag + "recalling to lifestone.");
                try { CoreManager.Current.Actions.InvokeChatParser("/lifestone"); } catch { }
            }
            if (doLogout)
            {
                int delay = doRecall ? 25 : 3;   // after the cast, or (nearly) in place
                Chat(tag + "logout in " + delay + "s.");
                pendingLogout = DateTime.Now.AddSeconds(delay);
            }
        }
        void Chat(string msg)
        {
            try { Host.Actions.AddChatText(msg, 3); } catch { }
        }
    }
}
