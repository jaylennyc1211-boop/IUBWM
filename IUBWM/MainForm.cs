using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using IUBWM.Classes;
using System.Threading;
using System.Windows.Forms;

namespace IUBWM
{
    public partial class Main : Form
    {
        public Main()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {

        }

        private void radioButton5_CheckedChanged(object sender, EventArgs e)
        {

        }

        private void testButton_Click(object sender, EventArgs e)
        {
            Thread.Sleep(2000);
            InputSimulator.TypeText("THISSTRINGWASWRITTENBYTHEPROGRAMYAYYYYYYY");
        }
    }
}
