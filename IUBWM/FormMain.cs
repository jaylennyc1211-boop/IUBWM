using IUBWM.Classes;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace IUBWM
{
    public partial class FormMain : Form
    {
        // Main task variables
        private bool _isRunning = false;
        private CancellationTokenSource _mainCts;

        //Mode selector variables
        private int mode = 0;

        //AutoClicker task variables
        private CancellationTokenSource _autoClickerCts;
        private Task _autoClickerTask;
        private bool _autoClickerRunning = false;
        private bool autoClicker = false;

        //AutoWalk variables
        private bool autoWalk = false;

        //AutoCam variables
        private bool autoCam = false;
        private bool horizontal = false;
        private bool leftward = true;
        private CancellationTokenSource _autoCamCts;
        private Task _autoCamTask;
        private bool _autoCamRunning = false;

        //AutoToggle variables
        private bool autoToggle = false;
        private bool reaping = true;
        private CancellationTokenSource _autoToggleCts;
        private Task _autoToggleTask;
        private bool _autoToggleRunning = false;

        //AutoInteract variables
        private bool autoInteract = false;

        //Mixing mode variables
        private CancellationTokenSource _mixingLoopCts;
        private Task _mixingLoopTask;
        private bool _mixingLoopRunning = false;

        //Idling mode variables
        private CancellationTokenSource _idlingLoopCts;
        private Task _idlingLoopTask;
        private bool _idlingLoopRunning = false;

        //AutoStop variables
        private CancellationTokenSource _autoStopCts;
        private Task _autoStopTask;
        private bool _autoStopRunning = false;

        // Unique id for hotkey
        private const int HOTKEY_ID = 1;

        // Windows message id for hotkeys
        private const int WM_HOTKEY = 0x0312;

        //shitty faucet detector variables
        Bitmap previousCursor = null;

        [StructLayout(LayoutKind.Sequential)]
        private struct CURSORINFO
        {
            public int cbSize;
            public int flags;
            public IntPtr hCursor;
            public POINT ptScreenPos;
        }

        [DllImport("user32.dll")]
        private static extern bool GetCursorInfo(out CURSORINFO pci);

        [DllImport("user32.dll")]
        static extern IntPtr CopyIcon(IntPtr hIcon);

        [DllImport("user32.dll", SetLastError = true)]
        static extern bool DestroyIcon(IntPtr hIcon);

        [DllImport("user32.dll", SetLastError = true)]
        static extern bool GetIconInfo(IntPtr hIcon, out ICONINFO piconinfo);

        [DllImport("gdi32.dll")]
        static extern bool DeleteObject(IntPtr hObject);

        [StructLayout(LayoutKind.Sequential)]
        public struct ICONINFO
        {
            public bool fIcon;
            public int xHotspot;
            public int yHotspot;
            public IntPtr hbmMask;
            public IntPtr hbmColor;
        }

        Bitmap GetCursorBitmap()
        {
            CURSORINFO ci = new CURSORINFO();
            ci.cbSize = Marshal.SizeOf(typeof(CURSORINFO));
            GetCursorInfo(out ci);

            IntPtr hIcon = CopyIcon(ci.hCursor);

            ICONINFO iconInfo;
            GetIconInfo(hIcon, out iconInfo);

            Bitmap bmp = Bitmap.FromHbitmap(iconInfo.hbmColor);

            DeleteObject(iconInfo.hbmMask);
            DeleteObject(iconInfo.hbmColor);
            DestroyIcon(hIcon);

            return bmp;
        }

        bool CursorShapeChanged()
        {
            Bitmap current = GetCursorBitmap();

            if (previousCursor == null)
            {
                previousCursor = current;
                return false;
            }

            bool changed = !BitmapsEqual(previousCursor, current);

            previousCursor.Dispose();
            previousCursor = current;

            return changed;
        }

        bool BitmapsEqual(Bitmap a, Bitmap b)
        {
            if (a.Width != b.Width || a.Height != b.Height)
                return false;

            var rect = new Rectangle(0, 0, a.Width, a.Height);

            var bd1 = a.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            var bd2 = b.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);

            try
            {
                int bytes = Math.Abs(bd1.Stride) * a.Height;
                byte[] buffer1 = new byte[bytes];
                byte[] buffer2 = new byte[bytes];

                Marshal.Copy(bd1.Scan0, buffer1, 0, bytes);
                Marshal.Copy(bd2.Scan0, buffer2, 0, bytes);

                return buffer1.SequenceEqual(buffer2);
            }
            finally
            {
                a.UnlockBits(bd1);
                b.UnlockBits(bd2);
            }
        }







        // terrible horrible awful no good mouse input receiver
        private IntPtr _hookID = IntPtr.Zero;
        private LowLevelMouseProc _proc;
        private Action<int, int> _onPositionSelected;

        private IntPtr SetHook(LowLevelMouseProc proc)
        {
            using (Process curProcess = Process.GetCurrentProcess())
            using (ProcessModule curModule = curProcess.MainModule)
            {
                return SetWindowsHookEx(WH_MOUSE_LL, proc,
                    GetModuleHandle(curModule.ModuleName), 0);
            }
        }

        // The callback that receives mouse events
        private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && wParam == (IntPtr)WM_LBUTTONDOWN)
            {
                MSLLHOOKSTRUCT hookStruct =
                    Marshal.PtrToStructure<MSLLHOOKSTRUCT>(lParam);

                int x = hookStruct.pt.x;
                int y = hookStruct.pt.y;

                UnhookWindowsHookEx(_hookID);

                this.Invoke(new Action(() =>
                {
                    this.WindowState = FormWindowState.Normal;
                    _onPositionSelected?.Invoke(x, y);
                    _onPositionSelected = null;
                }));
            }

            return CallNextHookEx(_hookID, nCode, wParam, lParam);
        }

        private void StartPositionSelection(Action<int, int> onSelected)
        {
            _onPositionSelected = onSelected;

            this.WindowState = FormWindowState.Minimized;
            _hookID = SetHook(_proc);
        }

        private delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);

        [StructLayout(LayoutKind.Sequential)]
        private struct POINT
        {
            public int x;
            public int y;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MSLLHOOKSTRUCT
        {
            public POINT pt;
            public uint mouseData;
            public uint flags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        // P/Invoke definitions
        private const int WH_MOUSE_LL = 14;
        private const int WM_LBUTTONDOWN = 0x0201;



        [DllImport("user32.dll")]
        static extern int GetDpiForSystem();

        [DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, Keys vk);

        [DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        [DllImport("user32.dll")]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc lpfn,
        IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll")]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll")]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode,
            IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll")]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        // Modifiers
        private const uint MOD_NONE = 0x0000;
        private const uint MOD_ALT = 0x0001;
        private const uint MOD_CTRL = 0x0002;
        private const uint MOD_SHIFT = 0x0004;
        private const uint MOD_WIN = 0x0008;
        public FormMain()
        {
            InitializeComponent();
            _proc = HookCallback;

            // Register F7 as a global hotkey
            bool registered = RegisterHotKey(this.Handle, HOTKEY_ID, MOD_NONE, Keys.F7);
            if (!registered)
            {
                MessageBox.Show("Failed to register F7 hotkey. It may already be in use.", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void FormMain_Load(object sender, EventArgs e)
        {

        }

        protected override void OnFormClosed(FormClosedEventArgs e)
        {
            // Always unregister
            UnregisterHotKey(this.Handle, HOTKEY_ID);
            base.OnFormClosed(e);
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WM_HOTKEY && m.WParam.ToInt32() == HOTKEY_ID)
            {
                // F7 pressed - behave like Start/Stop toggle
                ToggleRunState();
            }

            base.WndProc(ref m);
        }

        private void startButton_Click(object sender, EventArgs e)
        {
            ToggleRunState();
        }

        private void stopButton_Click(object sender, EventArgs e)
        {
            ToggleRunState();
        }

        private void ToggleRunState()
        {
            if (_isRunning)
            {
                // Stop
                StopLoop();
                ChangeMode();
                ResetModeSelector();
            }
            else
            {
                // Start
                StartLoop();
                DisableAll();
            }
        }

        private void StartLoop()
        {
            if (_isRunning) return;

            _isRunning = true;
            _mainCts = new CancellationTokenSource();

            this.Invoke((Action)(() =>
            {
                startButton.Enabled = false;
                stopButton.Enabled = true;

                setupButton.Enabled = false;
            }));

            // Fire-and-forget background task
            _ = Task.Run(() => RunLoop(_mainCts.Token));
        }

        private void StopLoop()
        {
            if (!_isRunning) return;

            _mainCts?.Cancel();
            _isRunning = false;

            this.Invoke((Action)(() =>
            {
                startButton.Enabled = true;
                stopButton.Enabled = false;

                setupButton.Enabled = true;
            }));
        }

        private async Task RunLoop(CancellationToken token)
        {
            // Main one-time logic goes here !!!!!!!!!!!!!!!
            Random r = new Random();
            if (checkBoxAutoStop.Checked) StartAutoStop();
            if (mode == 0 || mode == 1 || mode == 2)
            {
                if (autoClicker) StartAutoClicker();
                if (autoCam) StartAutoCam();
                //if (autoInteract) StartAutoInteract();
                if (autoToggle)
                {
                    if (reaping)
                    {
                        InputSimulator.KeyDownScan(InputSimulator.SC_2);
                        Thread.Sleep(50);
                        InputSimulator.KeyUpScan(InputSimulator.SC_2);
                    }
                    else
                    {
                        InputSimulator.KeyDownScan(InputSimulator.SC_1);
                        Thread.Sleep(50);
                        InputSimulator.KeyUpScan(InputSimulator.SC_1);
                    }
                    StartAutoToggle();
                }
            }
            if (mode == 3) StartIdlingLoop();
            else if (mode == 5) StartMixingLoop();

            // Main loop logic goes here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            try
            {
                while (!token.IsCancellationRequested)
                {
                    if (autoWalk) InputSimulator.KeyDownScan(InputSimulator.SC_W);
                    if (autoInteract)
                    {
                        InputSimulator.KeyDownScan(InputSimulator.SC_E);
                        await Task.Delay(r.Next(1, Convert.ToInt32(variationPickerAutoInteract.Value) + 1));
                        InputSimulator.KeyUpScan(InputSimulator.SC_E);
                        await Task.Delay(Convert.ToInt32(delayPickerAutoInteract.Value) + r.Next(-Convert.ToInt32(variationPickerAutoInteract.Value), Convert.ToInt32(variationPickerAutoInteract.Value)+1));
                    }
                    await Task.Delay(50, token);
                }
            }
            catch (TaskCanceledException)
            {
            
            }
            finally
            {
                InputSimulator.KeyUpScan(InputSimulator.SC_W);
                StopAutoClicker();
                StopAutoCam();
                //StopAutoInteract();
                StopAutoToggle();
                StopIdlingLoop();
                StopMixingLoop();
                StopAutoStop();
            }

            // When loop ends, make sure UI resets on the UI thread
            this.BeginInvoke((Action)(() =>
            {
                _isRunning = false;
                startButton.Enabled = true;
                stopButton.Enabled = false;
                progressBarMixing.Value = 0;
                progressBarIdling.Value = 0;
            }));
        }

        private void StartAutoClicker()
        {
            if (_autoClickerRunning) return;

            _autoClickerRunning = true;
            _autoClickerCts = new CancellationTokenSource();

            // read delay/variation on UI thread once at the start,
            // OR read inside the loop if you want them live-updatable
            int baseDelay = 0;
            int variation = 0;

            this.Invoke((Action)(() =>
            {
                baseDelay = Convert.ToInt32(delayPicker.Value);
                variation = Convert.ToInt32(variationPicker.Value);
            }));

            _autoClickerTask = Task.Run(() => AutoClickerLoop(_autoClickerCts.Token, baseDelay, variation));
        }

        private void StopAutoClicker()
        {
            if (!_autoClickerRunning) return;

            _autoClickerCts?.Cancel();
            _autoClickerRunning = false;
        }

        private async Task AutoClickerLoop(CancellationToken token, int baseDelay, int variation)
        {
            var r = new Random();

            try
            {
                while (!token.IsCancellationRequested)
                {
                    // Perform click
                    InputSimulator.LeftClick(0);

                    // calculate delay with variation
                    int offset = r.Next(-variation, variation + 1);
                    int delay = baseDelay + offset;
                    if (delay < 1) delay = 1; // avoid zero or negative

                    try
                    {
                        await Task.Delay(delay, token);
                    }
                    catch (TaskCanceledException)
                    {
                        break;
                    }
                }
            }
            finally
            {
                _autoClickerRunning = false;
            }
        }


        private void checkBoxAutoWalk_CheckedChanged(object sender, EventArgs e)
        {
            autoWalk = checkBoxAutoWalk.Checked;
        }

        private void checkBoxAutoClicker_CheckedChanged(object sender, EventArgs e)
        {
            autoClicker = checkBoxAutoClicker.Checked;
        }

        private void checkBoxAutoCam_CheckedChanged(object sender, EventArgs e)
        {
            autoCam = checkBoxAutoCam.Checked;
        }

        private void checkBoxAutoToggle_CheckedChanged(object sender, EventArgs e)
        {
            autoToggle = checkBoxAutoToggle.Checked;
        }

        private void setupButton_Click(object sender, EventArgs e)
        {
            this.BeginInvoke((Action)(() =>
            {
                MessageBox.Show("VERSION 1.6: The Humanizing Update\n\nUPDATES\n-------------\nUI:\n - Replaced the unused Setup Automation button with the Changelog button\n\nMain functions:\n - Added AutoStop as an option to stop the program after a set amount of time\n - Updated the UI to fit these changes\n\nIdling:\n - Increased wait times to be less erratic\n - AutoInvite now moves the player away from their previous spot\n - Added clicking as a possible action\n - Updated the Action UI to show how many seconds the program waits\n\nBUGFIXES\n-------------\n - Fixed a huge oversight where selected custom options would still turn on even when Idling or Mixing mode was selected\n\nVERSION 1.6.1:\n\nUPDATES\n-------------\nAutoStop:\n - Made AutoStop significantly more robust and stable\n - Added a separate options group on the UI\n - Made the UI a lot more user friendly\n\nBUGFIXES\n-------------\nIdling:\n - Fixed a minor oversight where the progress bar wouldn't reset immediately after an invite has been sent\n\nVERSION 1.6.2\n\nUPDATES\n-------------\nIdling:\n - Reduced wait times to max 30s when AutoInvite is off");
            }));
        }

        private void ChangeMode()
        {
            this.BeginInvoke((Action)(() =>
            {
                switch(mode)
                {
                    default:
                    case 0:
                        checkBoxAutoClicker.Enabled = true;

                        labelDelay.Enabled = true;
                        delayPicker.Enabled = true;

                        labelVariation.Enabled = true;
                        variationPicker.Enabled = true;

                        checkBoxAutoWalk.Enabled = true;

                        checkBoxAutoToggle.Enabled = true;

                        labelInterval.Enabled = true;
                        intervalPicker.Enabled = true;

                        checkBoxAutoCam.Enabled = true;

                        //buttonLaningHorizontal.Enabled = true;

                        buttonLaningVertical.Enabled = true;

                        buttonLaningLeftward.Enabled = true;

                        buttonLaningRightward.Enabled = true;

                        autoCamModeReap.Enabled = true;

                        autoCamModeSow.Enabled = true;

                        checkBoxAutoInteract.Enabled = true;

                        delayPickerAutoInteract.Enabled = true;
                        labelDelayAutoInteract.Enabled = true;

                        variationPickerAutoInteract.Enabled = true;
                        labelVariationAutoInteract.Enabled = true;

                        labelFaucetX.Enabled = false;
                        faucetXPicker.Enabled = false;

                        labelFaucetY.Enabled = false;
                        faucetYPicker.Enabled = false;

                        positionSelector.Enabled = false;

                        labelTrickleTime.Enabled = false;
                        tricklePicker.Enabled = false;

                        labelMaxFlow.Enabled = false;
                        maxFlowPicker.Enabled = false;

                        checkBoxAutoInvite.Enabled = false;

                        labelHomeX.Enabled = false;
                        homeXPicker.Enabled = false;

                        labelHomeY.Enabled = false;
                        homeYPicker.Enabled = false;

                        labelInviteX.Enabled = false;
                        inviteXPicker.Enabled = false;

                        labelInviteY.Enabled = false;
                        inviteYPicker.Enabled = false;

                        positionSelectorHome.Enabled = false;
                        positionSelectorInvite.Enabled = false;
                        positionSelectorClose.Enabled = false;

                        labelCloseX.Enabled = false;
                        closeXPicker.Enabled = false;

                        labelCloseY.Enabled = false;
                        closeYPicker.Enabled = false;

                        checkBoxAutoStop.Enabled = true;

                        autoStopTimePicker.Enabled = true;
                        labelAutoStopTime.Enabled = true;
                        break;
                    case 1:
                        checkBoxAutoClicker.Enabled = false;
                        checkBoxAutoClicker.Checked = true;

                        labelDelay.Enabled = false;
                        delayPicker.Enabled = false;
                        delayPicker.Value = 200;

                        labelVariation.Enabled = false;
                        variationPicker.Enabled = false;
                        variationPicker.Value = 50;

                        checkBoxAutoWalk.Enabled = false;
                        checkBoxAutoWalk.Checked = true;

                        checkBoxAutoToggle.Enabled = false;
                        checkBoxAutoToggle.Checked = true;

                        labelInterval.Enabled = false;
                        intervalPicker.Enabled = false;
                        intervalPicker.Value = 1;

                        checkBoxAutoCam.Enabled = false;
                        checkBoxAutoCam.Checked = true;

                        //buttonLaningHorizontal.Enabled = true;

                        buttonLaningVertical.Enabled = true;

                        buttonLaningLeftward.Enabled = true;

                        buttonLaningRightward.Enabled = true;

                        autoCamModeReap.Enabled = true;
                        autoCamModeReap.Checked = true;

                        autoCamModeSow.Enabled = true;
                        autoCamModeSow.Checked = false;

                        checkBoxAutoInteract.Enabled = false;
                        checkBoxAutoInteract.Checked = false;

                        delayPickerAutoInteract.Enabled = false;
                        labelDelayAutoInteract.Enabled = false;

                        variationPickerAutoInteract.Enabled = false;
                        labelVariationAutoInteract.Enabled = false;

                        labelFaucetX.Enabled = false;
                        faucetXPicker.Enabled = false;

                        labelFaucetY.Enabled = false;
                        faucetYPicker.Enabled = false;

                        positionSelector.Enabled = false;

                        labelTrickleTime.Enabled = false;
                        tricklePicker.Enabled = false;

                        labelMaxFlow.Enabled = false;
                        maxFlowPicker.Enabled = false;

                        checkBoxAutoInvite.Enabled = false;

                        labelHomeX.Enabled = false;
                        homeXPicker.Enabled = false;

                        labelHomeY.Enabled = false;
                        homeYPicker.Enabled = false;

                        labelInviteX.Enabled = false;
                        inviteXPicker.Enabled = false;

                        labelInviteY.Enabled = false;
                        inviteYPicker.Enabled = false;

                        positionSelectorHome.Enabled = false;
                        positionSelectorInvite.Enabled = false;
                        positionSelectorClose.Enabled = false;

                        labelCloseX.Enabled = false;
                        closeXPicker.Enabled = false;

                        labelCloseY.Enabled = false;
                        closeYPicker.Enabled = false;

                        checkBoxAutoStop.Enabled = true;

                        autoStopTimePicker.Enabled = true;
                        labelAutoStopTime.Enabled = true;
                        break;
                    case 3:
                        checkBoxAutoClicker.Enabled = false;
                        checkBoxAutoClicker.Checked = false;

                        labelDelay.Enabled = false;
                        delayPicker.Enabled = false;

                        labelVariation.Enabled = false;
                        variationPicker.Enabled = false;

                        checkBoxAutoWalk.Enabled = false;
                        checkBoxAutoWalk.Checked = false;

                        checkBoxAutoToggle.Enabled = false;
                        checkBoxAutoToggle.Checked = false;

                        labelInterval.Enabled = false;
                        intervalPicker.Enabled = false;

                        checkBoxAutoCam.Enabled = false;
                        checkBoxAutoCam.Checked = false;

                        //buttonLaningHorizontal.Enabled = false;

                        buttonLaningVertical.Enabled = false;

                        buttonLaningLeftward.Enabled = false;

                        buttonLaningRightward.Enabled = false;

                        autoCamModeReap.Enabled = false;

                        autoCamModeSow.Enabled = false;

                        checkBoxAutoInteract.Enabled = false;
                        checkBoxAutoInteract.Checked = false;

                        delayPickerAutoInteract.Enabled = false;
                        labelDelayAutoInteract.Enabled = false;

                        variationPickerAutoInteract.Enabled = false;
                        labelVariationAutoInteract.Enabled = false;

                        labelFaucetX.Enabled = false;
                        faucetXPicker.Enabled = false;

                        labelFaucetY.Enabled = false;
                        faucetYPicker.Enabled = false;

                        positionSelector.Enabled = false;

                        labelTrickleTime.Enabled = false;
                        tricklePicker.Enabled = false;

                        labelMaxFlow.Enabled = false;
                        maxFlowPicker.Enabled = false;

                        checkBoxAutoInvite.Enabled = true;

                        labelHomeX.Enabled = true;
                        homeXPicker.Enabled = true;

                        labelHomeY.Enabled = true;
                        homeYPicker.Enabled = true;

                        labelInviteX.Enabled = true;
                        inviteXPicker.Enabled = true;

                        labelInviteY.Enabled = true;
                        inviteYPicker.Enabled = true;

                        positionSelectorHome.Enabled = true;
                        positionSelectorInvite.Enabled = true;
                        positionSelectorClose.Enabled = true;

                        labelCloseX.Enabled = true;
                        closeXPicker.Enabled = true;

                        labelCloseY.Enabled = true;
                        closeYPicker.Enabled = true;

                        checkBoxAutoStop.Enabled = true;

                        autoStopTimePicker.Enabled = true;
                        labelAutoStopTime.Enabled = true;
                        break;
                    case 4:
                        checkBoxAutoClicker.Enabled = false;
                        checkBoxAutoClicker.Checked = false;

                        labelDelay.Enabled = false;
                        delayPicker.Enabled = false;
                        delayPicker.Value = 200;

                        labelVariation.Enabled = false;
                        variationPicker.Enabled = false;
                        variationPicker.Value = 50;

                        checkBoxAutoWalk.Enabled = false;
                        checkBoxAutoWalk.Checked = true;

                        checkBoxAutoToggle.Enabled = false;
                        checkBoxAutoToggle.Checked = false;

                        labelInterval.Enabled = false;
                        intervalPicker.Enabled = false;
                        intervalPicker.Value = 1;

                        checkBoxAutoCam.Enabled = false;
                        checkBoxAutoCam.Checked = false;

                        //buttonLaningHorizontal.Enabled = false;

                        buttonLaningVertical.Enabled = false;

                        buttonLaningLeftward.Enabled = false;

                        buttonLaningRightward.Enabled = false;

                        autoCamModeReap.Enabled = false;

                        autoCamModeSow.Enabled = false;

                        checkBoxAutoInteract.Enabled = false;
                        checkBoxAutoInteract.Checked = true;

                        delayPickerAutoInteract.Enabled = false;
                        delayPickerAutoInteract.Value = 100;
                        labelDelayAutoInteract.Enabled = false;

                        variationPickerAutoInteract.Enabled = false;
                        variationPickerAutoInteract.Value = 25;
                        labelVariationAutoInteract.Enabled = false;

                        labelFaucetX.Enabled = false;
                        faucetXPicker.Enabled = false;

                        labelFaucetY.Enabled = false;
                        faucetYPicker.Enabled = false;

                        positionSelector.Enabled = false;

                        labelTrickleTime.Enabled = false;
                        tricklePicker.Enabled = false;

                        labelMaxFlow.Enabled = false;
                        maxFlowPicker.Enabled = false;

                        checkBoxAutoInvite.Enabled = false;

                        labelHomeX.Enabled = false;
                        homeXPicker.Enabled = false;

                        labelHomeY.Enabled = false;
                        homeYPicker.Enabled = false;

                        labelInviteX.Enabled = false;
                        inviteXPicker.Enabled = false;

                        labelInviteY.Enabled = false;
                        inviteYPicker.Enabled = false;

                        positionSelectorHome.Enabled = false;
                        positionSelectorInvite.Enabled = false;
                        positionSelectorClose.Enabled = false;

                        labelCloseX.Enabled = false;
                        closeXPicker.Enabled = false;

                        labelCloseY.Enabled = false;
                        closeYPicker.Enabled = false;

                        checkBoxAutoStop.Enabled = true;

                        autoStopTimePicker.Enabled = true;
                        labelAutoStopTime.Enabled = true;
                        break;
                    case 5:
                        checkBoxAutoClicker.Enabled = false;
                        checkBoxAutoClicker.Checked = false;

                        labelDelay.Enabled = false;
                        delayPicker.Enabled = false;

                        labelVariation.Enabled = false;
                        variationPicker.Enabled = false;

                        checkBoxAutoWalk.Enabled = false;
                        checkBoxAutoWalk.Checked = false;

                        checkBoxAutoToggle.Enabled = false;
                        checkBoxAutoToggle.Checked = false;

                        labelInterval.Enabled = false;
                        intervalPicker.Enabled = false;

                        checkBoxAutoCam.Enabled = false;
                        checkBoxAutoCam.Checked = false;

                        //buttonLaningHorizontal.Enabled = false;

                        buttonLaningVertical.Enabled = false;

                        buttonLaningLeftward.Enabled = false;

                        buttonLaningRightward.Enabled = false;

                        autoCamModeReap.Enabled = false;

                        autoCamModeSow.Enabled = false;

                        checkBoxAutoInteract.Enabled = false;
                        checkBoxAutoInteract.Checked = false;

                        delayPickerAutoInteract.Enabled = false;
                        labelDelayAutoInteract.Enabled = false;

                        variationPickerAutoInteract.Enabled = false;
                        labelVariationAutoInteract.Enabled = false;

                        labelFaucetX.Enabled = true;
                        faucetXPicker.Enabled = true;

                        labelFaucetY.Enabled = true;
                        faucetYPicker.Enabled = true;

                        positionSelector.Enabled = true;

                        labelTrickleTime.Enabled = true;
                        tricklePicker.Enabled = true;

                        labelMaxFlow.Enabled = true;
                        maxFlowPicker.Enabled = true;

                        checkBoxAutoInvite.Enabled = false;

                        labelHomeX.Enabled = false;
                        homeXPicker.Enabled = false;

                        labelHomeY.Enabled = false;
                        homeYPicker.Enabled = false;

                        labelInviteX.Enabled = false;
                        inviteXPicker.Enabled = false;

                        labelInviteY.Enabled = false;
                        inviteYPicker.Enabled = false;

                        positionSelectorHome.Enabled = false;
                        positionSelectorInvite.Enabled = false;
                        positionSelectorClose.Enabled = false;

                        labelCloseX.Enabled = false;
                        closeXPicker.Enabled = false;

                        labelCloseY.Enabled = false;
                        closeYPicker.Enabled = false;

                        checkBoxAutoStop.Enabled = true;

                        autoStopTimePicker.Enabled = true;
                        labelAutoStopTime.Enabled = true;
                        break;
                }
            }));
        }

        private void ResetModeSelector()
        {
            this.BeginInvoke((Action)(() =>
            {
                modeCustom.Enabled = true;
                mode1Lane.Enabled = true;
                modeIdle.Enabled = true;
                modeWheat.Enabled = true;
                modeMixing.Enabled = true;
            }));
        }

        private void DisableAll()
        {
            this.BeginInvoke((Action)(() =>
            {
                modeCustom.Enabled = false;
                mode1Lane.Enabled = false;
                modeIdle.Enabled = false;
                modeWheat.Enabled = false;
                modeMixing.Enabled = false;

                checkBoxAutoClicker.Enabled = false;
                labelDelay.Enabled = false;
                delayPicker.Enabled = false;
                labelVariation.Enabled = false;
                variationPicker.Enabled = false;
                checkBoxAutoWalk.Enabled = false;
                checkBoxAutoToggle.Enabled = false;
                labelInterval.Enabled = false;
                intervalPicker.Enabled = false;
                checkBoxAutoCam.Enabled = false;
                buttonLaningHorizontal.Enabled = false;
                buttonLaningVertical.Enabled = false;
                buttonLaningLeftward.Enabled = false;
                buttonLaningRightward.Enabled = false;
                autoCamModeReap.Enabled = false;
                autoCamModeSow.Enabled = false;
                checkBoxAutoInteract.Enabled = false;
                delayPickerAutoInteract.Enabled = false;
                labelDelayAutoInteract.Enabled = false;
                variationPickerAutoInteract.Enabled = false;
                labelVariationAutoInteract.Enabled = false;
                labelFaucetX.Enabled = false;
                labelFaucetY.Enabled = false;
                faucetXPicker.Enabled = false;
                faucetYPicker.Enabled = false;
                positionSelector.Enabled = false;
                labelTrickleTime.Enabled = false;
                tricklePicker.Enabled = false;
                labelMaxFlow.Enabled = false;
                maxFlowPicker.Enabled = false;
                checkBoxAutoInvite.Enabled = false;
                labelHomeX.Enabled = false;
                homeXPicker.Enabled = false;
                labelHomeY.Enabled = false;
                homeYPicker.Enabled = false;
                labelInviteX.Enabled = false;
                inviteXPicker.Enabled = false;
                labelInviteY.Enabled = false;
                inviteYPicker.Enabled = false;
                positionSelectorHome.Enabled = false;
                positionSelectorInvite.Enabled = false;
                positionSelectorClose.Enabled = false;
                labelCloseX.Enabled = false;
                closeXPicker.Enabled = false;
                labelCloseY.Enabled = false;
                closeYPicker.Enabled = false;
                checkBoxAutoStop.Enabled = false;
                autoStopTimePicker.Enabled = false;
                labelAutoStopTime.Enabled = false;
            }));
        }

        private void modeCustom_CheckedChanged(object sender, EventArgs e)
        {
            mode = 0;
            ChangeMode();
        }

        private void mode1Lane_CheckedChanged(object sender, EventArgs e)
        {
            mode = 1;
            ChangeMode();
        }
        private void modeField_CheckedChanged(object sender, EventArgs e)
        {
            mode = 2;
            ChangeMode();
        }

        private void modeIdle_CheckedChanged(object sender, EventArgs e)
        {
            mode = 3;
            ChangeMode();
        }

        private void modeWheat_CheckedChanged(object sender, EventArgs e)
        {
            mode = 4;
            ChangeMode();
        }

        private void modeMixing_CheckedChanged(object sender, EventArgs e)
        {
            mode = 5;
            ChangeMode();
        }

        private void buttonLaningHorizontal_CheckedChanged(object sender, EventArgs e)
        {
            horizontal = true;
        }

        private void buttonLaningVertical_CheckedChanged(object sender, EventArgs e)
        {
            horizontal = false;
        }

        private void buttonLaningLeftward_CheckedChanged(object sender, EventArgs e)
        {
            leftward = true;
        }

        private void buttonLaningRightward_CheckedChanged(object sender, EventArgs e)
        {
            leftward = false;
        }

        private void StartAutoCam()
        {
            if (_autoCamRunning) return;

            _autoCamRunning = true;
            _autoCamCts = new CancellationTokenSource();

            if (!autoCam)
            {
                _autoCamRunning = false;
                _autoCamCts.Cancel();
                return;
            }

            _autoCamTask = Task.Run(() =>
                AutoCamLoop(_autoCamCts.Token, horizontal, leftward));
        }

        private void StopAutoCam()
        {
            if (!_autoCamRunning) return;

            _autoCamCts?.Cancel();
            _autoCamRunning = false;
        }

        private async Task AutoCamLoop(CancellationToken token, bool horizontal, bool leftward)
        {
            int lengthReap = 9400;
            int widthReap = 2200;
            int lengthSow = 7600;
            int widthSow = 1600;
            //if (horizontal) lengthReap = 20000;
            //else lengthReap = 9000;

            try
            {
                while (!token.IsCancellationRequested)
                {
                    if (reaping)
                    {
                        await Task.Delay(lengthReap, token);
                        if (token.IsCancellationRequested) return;
                        InputSimulator.Turn90Degrees(leftward, 1);
                        await Task.Delay(widthReap, token);
                        if (token.IsCancellationRequested) return;
                        InputSimulator.Turn90Degrees(leftward, 1);
                        await Task.Delay(lengthReap, token);
                        if (token.IsCancellationRequested) return;
                        InputSimulator.Turn90Degrees(leftward, 1);
                        await Task.Delay(widthReap, token);
                        if (token.IsCancellationRequested) return;
                        InputSimulator.Turn90Degrees(leftward, 1);
                    }
                    else
                    {
                        await Task.Delay(lengthSow, token);
                        if (token.IsCancellationRequested) return;
                        InputSimulator.Turn90Degrees(leftward, 1);
                        await Task.Delay(widthSow, token);
                        if (token.IsCancellationRequested) return;
                        InputSimulator.Turn90Degrees(leftward, 1);
                        await Task.Delay(lengthSow, token);
                        if (token.IsCancellationRequested) return;
                        InputSimulator.Turn90Degrees(leftward, 1);
                        await Task.Delay(widthSow, token);
                        if (token.IsCancellationRequested) return;
                        InputSimulator.Turn90Degrees(leftward, 1);
                    }
                    if (leftward) InputSimulator.MoveMouseRelative(1, 0);
                    else InputSimulator.MoveMouseRelative(-1, 0);

                    if (autoToggle) ToggleHarvestMode();
                }
            }
            catch (TaskCanceledException)
            {

            }
            finally
            {
                _autoCamRunning = false;
            }
        }

        private void autoCamModeReap_CheckedChanged(object sender, EventArgs e)
        {
            reaping = true;
        }

        private void autoCamModeSow_CheckedChanged(object sender, EventArgs e)
        {
            reaping = false;
        }

        private void StartAutoToggle()
        {
            if (_autoToggleRunning) return;

            _autoToggleRunning = true;
            _autoToggleCts = new CancellationTokenSource();

            if (!autoToggle)
            {
                _autoToggleRunning = false;
                _autoToggleCts.Cancel();
                return;
            }

            _autoToggleTask = Task.Run(() =>
                AutoToggleLoop(_autoToggleCts.Token));
        }

        private void StopAutoToggle()
        {
            if (!_autoToggleRunning) return;

            _autoToggleCts?.Cancel();
            _autoToggleRunning = false;
        }

        private async Task AutoToggleLoop(CancellationToken token)
        {
            try
            {
                while(!token.IsCancellationRequested)
                {
                    if (!autoCam)
                    {
                        await Task.Delay(Convert.ToInt32(intervalPicker.Value));
                        if (token.IsCancellationRequested) return;
                        ToggleHarvestMode();
                    }
                }
            }
            finally
            {
                _autoToggleRunning = false;
            }
        }

        private void ToggleHarvestMode()
        {
            if (reaping)
            {
                reaping = !reaping;
                InputSimulator.KeyDownScan(InputSimulator.SC_1);
                Thread.Sleep(50);
                InputSimulator.KeyUpScan(InputSimulator.SC_1);
            }
            else
            {
                reaping = !reaping;
                InputSimulator.KeyDownScan(InputSimulator.SC_2);
                Thread.Sleep(50);
                InputSimulator.KeyUpScan(InputSimulator.SC_2);
            }
        }

        private void variationPicker_ValueChanged(object sender, EventArgs e)
        {
            if (delayPicker.Value - variationPicker.Value < 0)
            {
                variationPicker.Value = delayPicker.Value/2;
            }
        }

        private void variationPickerAutoInteract_ValueChanged(object sender, EventArgs e)
        {
            if (delayPickerAutoInteract.Value - variationPickerAutoInteract.Value < 0)
            {
                variationPickerAutoInteract.Value = delayPickerAutoInteract.Value/2;
            }
        }

        private void checkBoxAutoInteract_CheckedChanged(object sender, EventArgs e)
        {
            autoInteract = checkBoxAutoInteract.Checked;
        }

        private void StartMixingLoop()
        {
            if (_mixingLoopRunning) return;

            _mixingLoopRunning = true;
            _mixingLoopCts = new CancellationTokenSource();

            if (mode != 5)
            {
                _mixingLoopRunning = false;
                _mixingLoopCts.Cancel();
                return;
            }

            _mixingLoopTask = Task.Run(() =>
                MixingLoop(_mixingLoopCts.Token));
        }

        private void StopMixingLoop()
        {
            if (!_mixingLoopRunning) return;

            _mixingLoopCts?.Cancel();
            _mixingLoopRunning = false;
        }

        private async Task MixingLoop(CancellationToken token)
        {
            int trickleWaitTime = Convert.ToInt32(tricklePicker.Value);
            int fullFlowWaitTime = Convert.ToInt32(maxFlowPicker.Value);

            Random r = new Random();
            try
            {
                while (!token.IsCancellationRequested)
                {
                    bool faucetFound = false;
                    this.BeginInvoke((Action)(() =>
                    {
                        progressBarMixing.Value = 0;
                        progressBarMixing.Maximum = trickleWaitTime * 2;
                    }));
                    InputSimulator.MoveMouseAbsolute(Convert.ToInt32(faucetXPicker.Value), Convert.ToInt32(faucetYPicker.Value));
                    InputSimulator.MoveMouseRelative(-50, -50);
                    CursorShapeChanged();
                    while (!faucetFound)
                    {
                        InputSimulator.MoveMouseRelative(2, 2);
                        if (CursorShapeChanged())
                        {
                            faucetFound = true;
                        }
                        await Task.Delay(10, token);
                    }
                    await Task.Delay(30, token);
                    InputSimulator.LeftDown();
                    await Task.Delay(30, token);
                    for (int i = 0; i < 20; i++)
                    {
                        InputSimulator.MoveMouseRelative(10, 0);
                        await Task.Delay(1, token);
                    }
                    await Task.Delay(fullFlowWaitTime, token);
                    for (int i = 0; i < 19; i++)
                    {
                        InputSimulator.MoveMouseRelative(-10, 0);
                        await Task.Delay(3, token);
                    }
                    InputSimulator.MoveMouseRelative(15, 0);
                    await Task.Delay(50);
                    InputSimulator.LeftUp();

                    for (int i = 0; i < trickleWaitTime*2; i++)
                    {
                        this.BeginInvoke((Action)(() =>
                        {
                            progressBarMixing.Value++;
                        }));
                        await Task.Delay(500, token);
                    }

                    for (int i = 0; i < 10; i++)
                    {
                        InputSimulator.MoveMouseRelative(-26, 0);
                        await Task.Delay(1, token);
                    }
                    InputSimulator.MoveMouseRelative(-8, 0);

                    InputSimulator.KeyDownScan(InputSimulator.SC_W);
                    await Task.Delay(1700, token);
                    InputSimulator.KeyUpScan(InputSimulator.SC_W);
                    InputSimulator.KeyDownScan(InputSimulator.SC_E);
                    await Task.Delay(50 + r.Next(25), token);
                    InputSimulator.KeyUpScan(InputSimulator.SC_E);

                    for (int i = 0; i < 10; i++)
                    {
                        InputSimulator.MoveMouseRelative(52, 0);
                        await Task.Delay(1, token);
                    }
                    InputSimulator.MoveMouseRelative(16, 4);

                    InputSimulator.KeyDownScan(InputSimulator.SC_W);
                    InputSimulator.KeyDownScan(InputSimulator.SC_D);
                    await Task.Delay(50, token);
                    InputSimulator.KeyUpScan(InputSimulator.SC_D);
                    await Task.Delay(1350, token);
                    InputSimulator.KeyDownScan(InputSimulator.SC_E);
                    await Task.Delay(r.Next(1, Convert.ToInt32(variationPickerAutoInteract.Value) + 1));
                    InputSimulator.KeyUpScan(InputSimulator.SC_E);
                    await Task.Delay(200, token);
                    InputSimulator.KeyDownScan(InputSimulator.SC_E);
                    await Task.Delay(r.Next(1, Convert.ToInt32(variationPickerAutoInteract.Value) + 1));
                    InputSimulator.KeyUpScan(InputSimulator.SC_E);
                    InputSimulator.KeyUpScan(InputSimulator.SC_W);
                    InputSimulator.KeyDownScan(InputSimulator.SC_E);
                    await Task.Delay(50 + r.Next(25), token);
                    InputSimulator.KeyUpScan(InputSimulator.SC_E);
                    await Task.Delay(1000, token);
                }
            }
            catch (TaskCanceledException)
            {

            }
            finally
            {
                _mixingLoopRunning = false;
            }
        }

        private void positionSelector_Click(object sender, EventArgs e)
        {
            StartPositionSelection((x, y) =>
            {
                faucetXPicker.Value = x;
                faucetYPicker.Value = y;
            });
        }

        private void positionSelectorHome_Click(object sender, EventArgs e)
        {
            StartPositionSelection((x, y) =>
            {
                homeXPicker.Value = x;
                homeYPicker.Value = y;
            });
        }

        private void positionSelectorInvite_Click(object sender, EventArgs e)
        {
            StartPositionSelection((x, y) =>
            {
                inviteXPicker.Value = x;
                inviteYPicker.Value = y;
            });
        }

        private void StartIdlingLoop()
        {
            if (_idlingLoopRunning) return;

            _idlingLoopRunning = true;
            _idlingLoopCts = new CancellationTokenSource();

            if (mode != 3)
            {
                _idlingLoopRunning = false;
                _idlingLoopCts.Cancel();
                return;
            }

            _idlingLoopTask = Task.Run(() =>
                IdlingLoop(_idlingLoopCts.Token));
        }

        private void StopIdlingLoop()
        {
            if (!_idlingLoopRunning) return;

            _idlingLoopCts?.Cancel();
            _idlingLoopRunning = false;
        }

        private async Task IdlingLoop(CancellationToken token)
        {
            Random r = new Random();
            Stopwatch inviteTimer = new Stopwatch();
            int randomTime = 0;
            try
            {
                if (checkBoxAutoInvite.Checked)
                {
                    this.BeginInvoke((Action)(() =>
                    {
                        labelAction.Text = "Invite";
                    }));
                    InputSimulator.MoveMouseAbsolute(Convert.ToInt32(homeXPicker.Value), Convert.ToInt32(homeYPicker.Value));
                    InputSimulator.MoveMouseRelative(1, 0);
                    InputSimulator.LeftClick();
                    await Task.Delay(100, token);
                    InputSimulator.MoveMouseAbsolute(Convert.ToInt32(inviteXPicker.Value), Convert.ToInt32(inviteYPicker.Value));
                    InputSimulator.MoveMouseRelative(1, 0);
                    InputSimulator.LeftClick();
                    await Task.Delay(100, token);
                    InputSimulator.MoveMouseAbsolute(Convert.ToInt32(closeXPicker.Value), Convert.ToInt32(closeYPicker.Value));
                    InputSimulator.MoveMouseRelative(1, 0);
                    InputSimulator.LeftClick();
                }
                inviteTimer.Start();
                while (!token.IsCancellationRequested)
                {
                    randomTime = 500 * r.Next(40, 60);
                    this.BeginInvoke((Action)(() =>
                    {
                        labelAction.Text = $"Wait {randomTime/1000}s";
                    }));
                    await Task.Delay(randomTime, token);
                    switch (r.Next(12))
                    {
                        default:
                        case 0:
                            if (checkBoxAutoInvite.Checked)
                            {
                                randomTime = 500 * r.Next(120, 241);
                                this.BeginInvoke((Action)(() =>
                                {
                                    labelAction.Text = $"Wait {randomTime/1000}s (Host)";
                                }));
                                await Task.Delay(randomTime, token);
                            }
                            break;
                        case 1:
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Move Left";
                            }));
                            randomTime = 500 * r.Next(1, 3);
                            InputSimulator.KeyDownScan(InputSimulator.SC_A);
                            await Task.Delay(randomTime, token);
                            InputSimulator.KeyUpScan(InputSimulator.SC_A);
                            break;
                        case 2:
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Move Forward";
                            }));
                            randomTime = 500 * r.Next(1, 3);
                            InputSimulator.KeyDownScan(InputSimulator.SC_W);
                            await Task.Delay(randomTime, token);
                            InputSimulator.KeyUpScan(InputSimulator.SC_W);
                            break;
                        case 3:
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Move Back";
                            }));
                            randomTime = 500 * r.Next(1, 3);
                            InputSimulator.KeyDownScan(InputSimulator.SC_S);
                            await Task.Delay(randomTime, token);
                            InputSimulator.KeyUpScan(InputSimulator.SC_S);
                            break;
                        case 4:
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Move Right";
                            }));
                            randomTime = 500 * r.Next(1, 3);
                            InputSimulator.KeyDownScan(InputSimulator.SC_D);
                            await Task.Delay(randomTime, token);
                            InputSimulator.KeyUpScan(InputSimulator.SC_D);
                            break;
                        case 5:
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Jump";
                            }));
                            InputSimulator.KeyDownScan(InputSimulator.SC_SPACE);
                            await Task.Delay(50, token);
                            InputSimulator.KeyUpScan(InputSimulator.SC_SPACE);
                            InputSimulator.KeyDownScan(InputSimulator.SC_S);
                            await Task.Delay(1000, token);
                            InputSimulator.KeyUpScan(InputSimulator.SC_S);
                            break;
                        case 6:
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Turn Cam";
                            }));
                            InputSimulator.MoveMouseAbsolute(600, 540);
                            InputSimulator.RightDown();
                            randomTime = r.Next(20, 100);
                            for (int i = 0; i < randomTime; i++)
                            {
                                InputSimulator.MoveMouseRelative(1, 0);
                                await Task.Delay(1, token);
                            }
                            InputSimulator.RightUp();
                            break;
                        case 7:
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Turn Cam";
                            }));
                            InputSimulator.MoveMouseAbsolute(600, 540);
                            InputSimulator.RightDown();
                            randomTime = r.Next(20, 100);
                            for (int i = 0; i < randomTime; i++)
                            {
                                InputSimulator.MoveMouseRelative(-1, 0);
                                await Task.Delay(1, token);
                            }
                            InputSimulator.RightUp();
                            break;
                        case 8:
                        case 9:
                        case 10:
                        case 11:
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Click";
                            }));
                            InputSimulator.LeftClick();
                            await Task.Delay(100, token);
                            break;
                    }
                    this.BeginInvoke((Action)(() =>
                    {
                        if (Convert.ToInt32(inviteTimer.ElapsedMilliseconds) <= 300000) progressBarIdling.Value = Convert.ToInt32(inviteTimer.ElapsedMilliseconds) / 3000;
                    }));
                    if (inviteTimer.ElapsedMilliseconds >= 300000)
                    {
                        if (checkBoxAutoInvite.Checked)
                        {
                            this.BeginInvoke((Action)(() =>
                            {
                                labelAction.Text = "Invite";
                            }));
                            InputSimulator.MoveMouseAbsolute(Convert.ToInt32(homeXPicker.Value), Convert.ToInt32(homeYPicker.Value));
                            InputSimulator.MoveMouseRelative(1, 0);
                            InputSimulator.LeftClick();
                            await Task.Delay(100);
                            InputSimulator.MoveMouseAbsolute(Convert.ToInt32(inviteXPicker.Value), Convert.ToInt32(inviteYPicker.Value));
                            InputSimulator.MoveMouseRelative(1, 0);
                            InputSimulator.LeftClick();
                            await Task.Delay(100);
                            InputSimulator.MoveMouseAbsolute(Convert.ToInt32(closeXPicker.Value), Convert.ToInt32(closeYPicker.Value));
                            InputSimulator.MoveMouseRelative(1, 0);
                            InputSimulator.LeftClick();

                            InputSimulator.KeyDownScan(InputSimulator.SC_SPACE);
                            await Task.Delay(50, token);
                            InputSimulator.KeyUpScan(InputSimulator.SC_SPACE);
                            switch (r.Next(4))
                            {
                                default:
                                case 0:
                                    InputSimulator.KeyDownScan(InputSimulator.SC_W);
                                    break;
                                case 1:
                                    InputSimulator.KeyDownScan(InputSimulator.SC_A);
                                    break;
                                case 2:
                                    InputSimulator.KeyDownScan(InputSimulator.SC_S);
                                    break;
                                case 3:
                                    InputSimulator.KeyDownScan(InputSimulator.SC_D);
                                    break;
                            }
                            await Task.Delay(4000, token);
                            InputSimulator.KeyUpScan(InputSimulator.SC_W);
                            InputSimulator.KeyUpScan(InputSimulator.SC_A);
                            InputSimulator.KeyUpScan(InputSimulator.SC_S);
                            InputSimulator.KeyUpScan(InputSimulator.SC_D);
                        }
                        inviteTimer.Restart();
                        this.BeginInvoke((Action)(() =>
                        {
                            progressBarIdling.Value = 0;
                        }));
                    }
                }
                inviteTimer.Stop();
            }
            catch (TaskCanceledException)
            {

            }
            finally
            {
                _idlingLoopRunning = false;
                this.BeginInvoke((Action)(() =>
                {
                    labelAction.Text = "...";
                }));
            }
        }

        private void positionSelectorClose_Click(object sender, EventArgs e)
        {
            StartPositionSelection((x, y) =>
            {
                closeXPicker.Value = x;
                closeYPicker.Value = y;
            });
        }

        private void StartAutoStop()
        {
            if (_autoStopRunning) return;

            _autoStopRunning = true;
            _autoStopCts = new CancellationTokenSource();

            if (!checkBoxAutoStop.Checked)
            {
                _autoStopRunning = false;
                _autoStopCts.Cancel();
                return;
            }

            _autoStopTask = Task.Run(() =>
                AutoStopMain(_autoStopCts.Token));
        }

        private void StopAutoStop()
        {
            if (!_autoStopRunning) return;

            _autoStopCts?.Cancel();
            _autoStopRunning = false;
        }

        private async Task AutoStopMain(CancellationToken token)
        {
            int minutes = Convert.ToInt32(autoStopTimePicker.Value);
            int seconds = minutes * 60;
            try
            {
                this.BeginInvoke((Action)(() =>
                {
                    progressBarAutoStop.Value = 0;
                    progressBarAutoStop.Maximum = seconds;
                    labelAutoStopTimer.Text = string.Format("{0:00}:{1:00}:{2:00}", seconds / 3600, (seconds % 3600) / 60, seconds % 60);
                }));
                while (!token.IsCancellationRequested)
                {
                    await Task.Delay(1000, token);
                    if (seconds > 0) seconds--;
                    this.BeginInvoke((Action)(() =>
                    {
                        labelAutoStopTimer.Text = string.Format("{0:00}:{1:00}:{2:00}", seconds / 3600, (seconds % 3600) / 60, seconds % 60);
                        progressBarAutoStop.Value = minutes * 60 - seconds;
                    }));
                    if (seconds <= 0 && _isRunning)
                    {
                        ToggleRunState();
                    }
                }
            }
            catch (TaskCanceledException)
            {

            }
            finally
            {
                _autoStopRunning = false;

                this.BeginInvoke((Action)(() =>
                {
                    labelAutoStopTimer.Text = "00:00:00";
                }));
            }
        }
    }
}