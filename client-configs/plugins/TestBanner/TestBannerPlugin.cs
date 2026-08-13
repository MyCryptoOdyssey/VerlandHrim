// TestBanner v2 - vitals-bar-style banner shown ONLY on the TEST server.
// The visual replacement for the retired ugly WorldName (WORKSHOP field
// note 14).
//
// v2 punch-list (founder, 2026-08-02): wider (460, vitals-bar width), RED
// background, WHITE centered text, Virindi-bar icon (portal dat 0x1EF5) to
// toggle like LeakWatch/DerethWatch, native title-bar X to hide.
//
// Detection: CharacterFilter.Server compared ORDINAL (byte-exact) against
// the hardcoded test world name - same spirit as the Thwarg rule. On prod
// the plugin creates NO view, therefore NO bar icon: fully dormant.
//
// Hide/show: title-bar X hides; the Virindi-bar icon (present only while
// connected to Test) brings it back. Nothing to remember between sessions.
//
// Build: build.bat   Register: Decal > Add > Browse > TestBanner.dll
using System;
using System.Diagnostics;
using System.Drawing;
using Decal.Adapter;
using Decal.Adapter.Wrappers;

namespace TestBanner
{
    [FriendlyName("TestBanner")]
    public class PluginCore : PluginBase
    {
        // MUST stay byte-identical to Test's WorldName (which itself must
        // stay byte-identical to its ThwargLauncher entry - field note 14).
        // If the test world is ever renamed, this is the third place to edit.
        const string TEST_WORLD = "Test_Verland_Hrim";

        // Banner geometry: view client area is 460x20 (view.xml); tweak
        // width there AND here together.
        const int BANNER_W = 460, BANNER_H = 20;

        VirindiViewService.HudView view;

        protected override void Startup()
        {
            try
            {
                CoreManager.Current.CharacterFilter.LoginComplete += CharacterFilter_LoginComplete;
                CoreManager.Current.CharacterFilter.Logoff += CharacterFilter_Logoff;
                // Hot-reload trap (verified in OracleOfDereth): if the plugin
                // loads while already in-world, LoginComplete never fires.
                if (CoreManager.Current.CharacterFilter.LoginStatus >= 1)
                    EvaluateWorld();
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }

        protected override void Shutdown()
        {
            try
            {
                CoreManager.Current.CharacterFilter.LoginComplete -= CharacterFilter_LoginComplete;
                CoreManager.Current.CharacterFilter.Logoff -= CharacterFilter_Logoff;
                DestroyView();
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }

        void CharacterFilter_LoginComplete(object sender, EventArgs e)
        {
            try { EvaluateWorld(); }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }

        void CharacterFilter_Logoff(object sender, LogoffEventArgs e)
        {
            try { DestroyView(); }         // char select: no banner, no icon
            catch (Exception ex) { Debug.WriteLine(ex); }
        }

        void EvaluateWorld()
        {
            string world = null;
            try { world = CoreManager.Current.CharacterFilter.Server; } catch { }
            if (string.Equals(world, TEST_WORLD, StringComparison.Ordinal))
                ShowBanner();
            else
                DestroyView();
        }

        void ShowBanner()
        {
            try
            {
                if (view != null) { view.Visible = true; return; }

                VirindiViewService.ViewProperties properties;
                VirindiViewService.ControlGroup controls;
                var parser = new VirindiViewService.XMLParsers.Decal3XMLParser();
                parser.ParseFromResource("TestBanner.ViewXML.xml", out properties, out controls);
                view = new VirindiViewService.HudView(properties, controls);
                // ShowInBar defaults TRUE (LeakWatch pattern) - the 0x1EF5
                // icon appears in the Virindi bar and toggles visibility.

                var layout = (VirindiViewService.Controls.HudFixedLayout)view["bannerLayout"];

                // Background first (z-order: earlier = beneath)
                var bg = new VirindiViewService.Controls.HudPictureBox();
                bg.Image = new VirindiViewService.ACImage(Color.FromArgb(255, 190, 25, 25));
                layout.AddControl(bg, new Rectangle(0, 0, BANNER_W, BANNER_H));

                // White centered text on top
                var lbl = new VirindiViewService.Controls.HudStaticText();
                lbl.Text = "TEST SERVER";
                lbl.TextAlignment = VirindiViewService.WriteTextFormats.Center;
                try { lbl.TextColor = Color.White; } catch { }
                layout.AddControl(lbl, new Rectangle(0, 2, BANNER_W, BANNER_H - 4));

                view.Visible = true;
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }

        void DestroyView()
        {
            try
            {
                if (view != null) { view.Dispose(); view = null; }
            }
            catch (Exception ex) { Debug.WriteLine(ex); }
        }
    }
}
