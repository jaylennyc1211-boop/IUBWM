using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;

namespace IUBWM.Classes
{
    public static class InputSimulator
    {
        // --- WinAPI definitions ---

        [Flags]
        private enum InputType : uint
        {
            INPUT_MOUSE = 0,
            INPUT_KEYBOARD = 1,
            INPUT_HARDWARE = 2
        }

        [Flags]
        private enum MouseEventFlags : uint
        {
            MOUSEEVENTF_MOVE = 0x0001,
            MOUSEEVENTF_LEFTDOWN = 0x0002,
            MOUSEEVENTF_LEFTUP = 0x0004,
            MOUSEEVENTF_RIGHTDOWN = 0x0008,
            MOUSEEVENTF_RIGHTUP = 0x0010,
            MOUSEEVENTF_MIDDLEDOWN = 0x0020,
            MOUSEEVENTF_MIDDLEUP = 0x0040,
            MOUSEEVENTF_WHEEL = 0x0800,
            MOUSEEVENTF_ABSOLUTE = 0x8000
        }

        [Flags]
        private enum KeyboardEventFlags : uint
        {
            KEYEVENTF_EXTENDEDKEY = 0x0001,
            KEYEVENTF_KEYUP = 0x0002,
            KEYEVENTF_UNICODE = 0x0004,
            KEYEVENTF_SCANCODE = 0x0008
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT
        {
            public InputType type;
            public InputUnion U;
            public static int Size => Marshal.SizeOf(typeof(INPUT));
        }

        [StructLayout(LayoutKind.Explicit)]
        private struct InputUnion
        {
            [FieldOffset(0)] public MOUSEINPUT mi;
            [FieldOffset(0)] public KEYBDINPUT ki;
            [FieldOffset(0)] public HARDWAREINPUT hi;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MOUSEINPUT
        {
            public int dx;
            public int dy;
            public int mouseData;
            public MouseEventFlags dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct KEYBDINPUT
        {
            public ushort wVk;
            public ushort wScan;
            public KeyboardEventFlags dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct HARDWAREINPUT
        {
            public uint uMsg;
            public ushort wParamL;
            public ushort wParamH;
        }

        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

        [DllImport("user32.dll")]
        private static extern bool SetCursorPos(int X, int Y);

        // Letter keys (A–Z) - make (key down) scan codes
        public const ushort SC_A = 0x1E;
        public const ushort SC_B = 0x30;
        public const ushort SC_C = 0x2E;
        public const ushort SC_D = 0x20;
        public const ushort SC_E = 0x12;
        public const ushort SC_F = 0x21;
        public const ushort SC_G = 0x22;
        public const ushort SC_H = 0x23;
        public const ushort SC_I = 0x17;
        public const ushort SC_J = 0x24;
        public const ushort SC_K = 0x25;
        public const ushort SC_L = 0x26;
        public const ushort SC_M = 0x32;
        public const ushort SC_N = 0x31;
        public const ushort SC_O = 0x18;
        public const ushort SC_P = 0x19;
        public const ushort SC_Q = 0x10;
        public const ushort SC_R = 0x13;
        public const ushort SC_S = 0x1F;
        public const ushort SC_T = 0x14;
        public const ushort SC_U = 0x16;
        public const ushort SC_V = 0x2F;
        public const ushort SC_W = 0x11;
        public const ushort SC_X = 0x2D;
        public const ushort SC_Y = 0x15;
        public const ushort SC_Z = 0x2C;

        // Number keys (top row) - make (key down) scan codes
        public const ushort SC_1 = 0x02;
        public const ushort SC_2 = 0x03;
        public const ushort SC_3 = 0x04;
        public const ushort SC_4 = 0x05;
        public const ushort SC_5 = 0x06;
        public const ushort SC_6 = 0x07;
        public const ushort SC_7 = 0x08;
        public const ushort SC_8 = 0x09;
        public const ushort SC_9 = 0x0A;
        public const ushort SC_0 = 0x0B;

        public const ushort SC_SPACE = 0x39;

        public static void KeyDownScan(ushort scanCode)
        {
            var input = new INPUT
            {
                type = InputType.INPUT_KEYBOARD,
                U = new InputUnion
                {
                    ki = new KEYBDINPUT
                    {
                        wVk = 0,
                        wScan = scanCode,
                        dwFlags = KeyboardEventFlags.KEYEVENTF_SCANCODE,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };

            SendInput(1, new[] { input }, INPUT.Size);
        }

        public static void KeyUpScan(ushort scanCode)
        {
            var input = new INPUT
            {
                type = InputType.INPUT_KEYBOARD,
                U = new InputUnion
                {
                    ki = new KEYBDINPUT
                    {
                        wVk = 0,
                        wScan = scanCode,
                        dwFlags = KeyboardEventFlags.KEYEVENTF_SCANCODE | KeyboardEventFlags.KEYEVENTF_KEYUP,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };

            SendInput(1, new[] { input }, INPUT.Size);
        }

        // --- Public helper methods ---

        /// <summary>
        /// Move the mouse relative to its current position, with hardware input.
        /// </summary>
        public static void MoveMouseRelative(int dx, int dy)
        {
            var input = new INPUT
            {
                type = InputType.INPUT_MOUSE,
                U = new InputUnion
                {
                    mi = new MOUSEINPUT
                    {
                        dx = dx,
                        dy = dy,
                        mouseData = 0,
                        dwFlags = MouseEventFlags.MOUSEEVENTF_MOVE,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };

            SendInput(1, new[] { input }, INPUT.Size);
        }

        /// <summary>
        /// Rotate the in-game camera 90 degrees to the left or right.
        /// WARNING! EVERY 360 ROTATION OVER-ROTATES BY 1 PIXEL!
        /// </summary>
        public static void Turn90Degrees(bool left = false, int delay = 0)
        {
            if (left)
            {
                for (int i = 0; i < 26; i++)
                {
                    InputSimulator.MoveMouseRelative(-10, 0);
                    Thread.Sleep(delay);
                }
                InputSimulator.MoveMouseRelative(-8, 0);
            }
            else
            {
                for (int i = 0; i < 26; i++)
                {
                    InputSimulator.MoveMouseRelative(10, 0);
                    Thread.Sleep(delay);
                }
                InputSimulator.MoveMouseRelative(8, 0);
            }
        }

        /// <summary>
        /// Move the mouse cursor without hardware input to an absolute position on the screen.
        /// </summary>
        public static void MoveMouseAbsolute(int x, int y)
        {
            SetCursorPos(x, y);
        }

        /// <summary>
        /// Left mouse click at the current cursor position.
        /// </summary>
        public static void LeftClick(int delayBetween = 10)
        {
            var inputs = new INPUT[2];

            inputs[0].type = InputType.INPUT_MOUSE;
            inputs[0].U.mi = new MOUSEINPUT
            {
                dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTDOWN
            };

            inputs[1].type = InputType.INPUT_MOUSE;
            inputs[1].U.mi = new MOUSEINPUT
            {
                dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTUP
            };

            SendInput((uint)inputs.Length, inputs, INPUT.Size);
            if (delayBetween > 0)
                Thread.Sleep(delayBetween);
        }

        /// <summary>
        /// Begins holding down the left mouse button.
        /// </summary>
        public static void LeftDown()
        {
            var input = new INPUT[1];

            input[0].type = InputType.INPUT_MOUSE;
            input[0].U.mi = new MOUSEINPUT
            {
                dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTDOWN
            };

            SendInput((uint)1, input, INPUT.Size);
        }

        /// <summary>
        /// Raises the left mouse button.
        /// </summary>
        public static void LeftUp()
        {
            var input = new INPUT[1];

            input[0].type = InputType.INPUT_MOUSE;
            input[0].U.mi = new MOUSEINPUT
            {
                dwFlags = MouseEventFlags.MOUSEEVENTF_LEFTUP
            };

            SendInput((uint)1, input, INPUT.Size);
        }

        /// <summary>
        /// Right mouse click at the current cursor position.
        /// </summary>
        public static void RightClick(int delayBetween = 10)
        {
            var inputs = new INPUT[2];

            inputs[0].type = InputType.INPUT_MOUSE;
            inputs[0].U.mi = new MOUSEINPUT
            {
                dwFlags = MouseEventFlags.MOUSEEVENTF_RIGHTDOWN
            };

            inputs[1].type = InputType.INPUT_MOUSE;
            inputs[1].U.mi = new MOUSEINPUT
            {
                dwFlags = MouseEventFlags.MOUSEEVENTF_RIGHTUP
            };

            SendInput((uint)inputs.Length, inputs, INPUT.Size);
            if (delayBetween > 0)
                Thread.Sleep(delayBetween);
        }

        /// <summary>
        /// Begins holding down the right mouse button.
        /// </summary>
        public static void RightDown()
        {
            var input = new INPUT[1];

            input[0].type = InputType.INPUT_MOUSE;
            input[0].U.mi = new MOUSEINPUT
            {
                dwFlags = MouseEventFlags.MOUSEEVENTF_RIGHTDOWN
            };

            SendInput((uint)1, input, INPUT.Size);
        }

        /// <summary>
        /// Raises the right mouse button.
        /// </summary>
        public static void RightUp()
        {
            var input = new INPUT[1];

            input[0].type = InputType.INPUT_MOUSE;
            input[0].U.mi = new MOUSEINPUT
            {
                dwFlags = MouseEventFlags.MOUSEEVENTF_RIGHTUP
            };

            SendInput((uint)1, input, INPUT.Size);
        }
    }
}
