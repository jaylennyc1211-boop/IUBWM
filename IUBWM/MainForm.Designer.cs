namespace IUBWM
{
    partial class Main
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.modeSelectorBox = new System.Windows.Forms.GroupBox();
            this.modeWheat = new System.Windows.Forms.RadioButton();
            this.modeMixing = new System.Windows.Forms.RadioButton();
            this.modeField = new System.Windows.Forms.RadioButton();
            this.mode1Lane = new System.Windows.Forms.RadioButton();
            this.modeCustom = new System.Windows.Forms.RadioButton();
            this.label1 = new System.Windows.Forms.Label();
            this.startButton = new System.Windows.Forms.Button();
            this.stopButton = new System.Windows.Forms.Button();
            this.customOptionsBox = new System.Windows.Forms.GroupBox();
            this.checkBox1 = new System.Windows.Forms.CheckBox();
            this.checkBox2 = new System.Windows.Forms.CheckBox();
            this.comboBox1 = new System.Windows.Forms.ComboBox();
            this.label2 = new System.Windows.Forms.Label();
            this.checkBox3 = new System.Windows.Forms.CheckBox();
            this.checkBox4 = new System.Windows.Forms.CheckBox();
            this.testButton = new System.Windows.Forms.Button();
            this.modeSelectorBox.SuspendLayout();
            this.customOptionsBox.SuspendLayout();
            this.SuspendLayout();
            // 
            // modeSelectorBox
            // 
            this.modeSelectorBox.BackColor = System.Drawing.Color.Transparent;
            this.modeSelectorBox.Controls.Add(this.modeWheat);
            this.modeSelectorBox.Controls.Add(this.modeMixing);
            this.modeSelectorBox.Controls.Add(this.modeField);
            this.modeSelectorBox.Controls.Add(this.mode1Lane);
            this.modeSelectorBox.Controls.Add(this.modeCustom);
            this.modeSelectorBox.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.modeSelectorBox.ForeColor = System.Drawing.Color.White;
            this.modeSelectorBox.Location = new System.Drawing.Point(12, 64);
            this.modeSelectorBox.Name = "modeSelectorBox";
            this.modeSelectorBox.Size = new System.Drawing.Size(108, 159);
            this.modeSelectorBox.TabIndex = 0;
            this.modeSelectorBox.TabStop = false;
            this.modeSelectorBox.Text = "Select mode";
            // 
            // modeWheat
            // 
            this.modeWheat.AutoSize = true;
            this.modeWheat.Location = new System.Drawing.Point(6, 99);
            this.modeWheat.Name = "modeWheat";
            this.modeWheat.Size = new System.Drawing.Size(67, 20);
            this.modeWheat.TabIndex = 4;
            this.modeWheat.TabStop = true;
            this.modeWheat.Text = "Wheat";
            this.modeWheat.UseVisualStyleBackColor = true;
            this.modeWheat.CheckedChanged += new System.EventHandler(this.radioButton5_CheckedChanged);
            // 
            // modeMixing
            // 
            this.modeMixing.AutoSize = true;
            this.modeMixing.Location = new System.Drawing.Point(6, 125);
            this.modeMixing.Name = "modeMixing";
            this.modeMixing.Size = new System.Drawing.Size(66, 20);
            this.modeMixing.TabIndex = 3;
            this.modeMixing.TabStop = true;
            this.modeMixing.Text = "Mixing";
            this.modeMixing.UseVisualStyleBackColor = true;
            // 
            // modeField
            // 
            this.modeField.AutoSize = true;
            this.modeField.Location = new System.Drawing.Point(6, 73);
            this.modeField.Name = "modeField";
            this.modeField.Size = new System.Drawing.Size(58, 20);
            this.modeField.TabIndex = 2;
            this.modeField.TabStop = true;
            this.modeField.Text = "Field";
            this.modeField.UseVisualStyleBackColor = true;
            // 
            // mode1Lane
            // 
            this.mode1Lane.AutoSize = true;
            this.mode1Lane.Location = new System.Drawing.Point(6, 47);
            this.mode1Lane.Name = "mode1Lane";
            this.mode1Lane.Size = new System.Drawing.Size(68, 20);
            this.mode1Lane.TabIndex = 1;
            this.mode1Lane.TabStop = true;
            this.mode1Lane.Text = "1 Lane";
            this.mode1Lane.UseVisualStyleBackColor = true;
            // 
            // modeCustom
            // 
            this.modeCustom.AutoSize = true;
            this.modeCustom.Location = new System.Drawing.Point(6, 21);
            this.modeCustom.Name = "modeCustom";
            this.modeCustom.Size = new System.Drawing.Size(73, 20);
            this.modeCustom.TabIndex = 0;
            this.modeCustom.TabStop = true;
            this.modeCustom.Text = "Custom";
            this.modeCustom.UseVisualStyleBackColor = true;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.BackColor = System.Drawing.Color.Transparent;
            this.label1.Font = new System.Drawing.Font("Comic Sans MS", 22.2F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.label1.Location = new System.Drawing.Point(102, 9);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(689, 52);
            this.label1.TabIndex = 1;
            this.label1.Text = "Insomniac Ultimate Breadwinner Macro";
            this.label1.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // startButton
            // 
            this.startButton.BackColor = System.Drawing.Color.Black;
            this.startButton.Location = new System.Drawing.Point(12, 466);
            this.startButton.Name = "startButton";
            this.startButton.Size = new System.Drawing.Size(169, 75);
            this.startButton.TabIndex = 2;
            this.startButton.Text = "Start (F7)";
            this.startButton.UseVisualStyleBackColor = false;
            // 
            // stopButton
            // 
            this.stopButton.BackColor = System.Drawing.Color.Black;
            this.stopButton.Location = new System.Drawing.Point(187, 466);
            this.stopButton.Name = "stopButton";
            this.stopButton.Size = new System.Drawing.Size(169, 75);
            this.stopButton.TabIndex = 3;
            this.stopButton.Text = "Stop (F7)";
            this.stopButton.UseVisualStyleBackColor = false;
            // 
            // customOptionsBox
            // 
            this.customOptionsBox.BackColor = System.Drawing.Color.Transparent;
            this.customOptionsBox.Controls.Add(this.checkBox4);
            this.customOptionsBox.Controls.Add(this.checkBox3);
            this.customOptionsBox.Controls.Add(this.comboBox1);
            this.customOptionsBox.Controls.Add(this.checkBox2);
            this.customOptionsBox.Controls.Add(this.label2);
            this.customOptionsBox.Controls.Add(this.checkBox1);
            this.customOptionsBox.ForeColor = System.Drawing.Color.White;
            this.customOptionsBox.Location = new System.Drawing.Point(126, 64);
            this.customOptionsBox.Name = "customOptionsBox";
            this.customOptionsBox.Size = new System.Drawing.Size(207, 396);
            this.customOptionsBox.TabIndex = 4;
            this.customOptionsBox.TabStop = false;
            this.customOptionsBox.Text = "Custom options";
            // 
            // checkBox1
            // 
            this.checkBox1.AutoSize = true;
            this.checkBox1.Location = new System.Drawing.Point(6, 21);
            this.checkBox1.Name = "checkBox1";
            this.checkBox1.Size = new System.Drawing.Size(97, 20);
            this.checkBox1.TabIndex = 0;
            this.checkBox1.Text = "AutoClicker";
            this.checkBox1.UseVisualStyleBackColor = true;
            // 
            // checkBox2
            // 
            this.checkBox2.AutoSize = true;
            this.checkBox2.Location = new System.Drawing.Point(6, 47);
            this.checkBox2.Name = "checkBox2";
            this.checkBox2.Size = new System.Drawing.Size(87, 20);
            this.checkBox2.TabIndex = 1;
            this.checkBox2.Text = "AutoWalk";
            this.checkBox2.UseVisualStyleBackColor = true;
            // 
            // comboBox1
            // 
            this.comboBox1.FormattingEnabled = true;
            this.comboBox1.Items.AddRange(new object[] {
            "TopLeft",
            "TopRight",
            "BottomLeft",
            "BottomRight"});
            this.comboBox1.Location = new System.Drawing.Point(108, 179);
            this.comboBox1.Name = "comboBox1";
            this.comboBox1.Size = new System.Drawing.Size(83, 24);
            this.comboBox1.TabIndex = 2;
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(6, 183);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(96, 16);
            this.label2.TabIndex = 3;
            this.label2.Text = "Starting corner:";
            // 
            // checkBox3
            // 
            this.checkBox3.AutoSize = true;
            this.checkBox3.Location = new System.Drawing.Point(6, 157);
            this.checkBox3.Name = "checkBox3";
            this.checkBox3.Size = new System.Drawing.Size(84, 20);
            this.checkBox3.TabIndex = 4;
            this.checkBox3.Text = "AutoCam";
            this.checkBox3.UseVisualStyleBackColor = true;
            // 
            // checkBox4
            // 
            this.checkBox4.AutoSize = true;
            this.checkBox4.Location = new System.Drawing.Point(6, 73);
            this.checkBox4.Name = "checkBox4";
            this.checkBox4.Size = new System.Drawing.Size(100, 20);
            this.checkBox4.TabIndex = 5;
            this.checkBox4.Text = "AutoToggle";
            this.checkBox4.UseVisualStyleBackColor = true;
            // 
            // testButton
            // 
            this.testButton.BackColor = System.Drawing.Color.Black;
            this.testButton.Font = new System.Drawing.Font("Microsoft Sans Serif", 22.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(238)));
            this.testButton.ForeColor = System.Drawing.Color.White;
            this.testButton.Location = new System.Drawing.Point(376, 148);
            this.testButton.Name = "testButton";
            this.testButton.Size = new System.Drawing.Size(463, 297);
            this.testButton.TabIndex = 5;
            this.testButton.Text = "TEST";
            this.testButton.UseVisualStyleBackColor = false;
            this.testButton.Click += new System.EventHandler(this.testButton_Click);
            // 
            // Main
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(8F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.Black;
            this.BackgroundImage = global::IUBWM.Properties.Resources.background;
            this.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.ClientSize = new System.Drawing.Size(882, 553);
            this.Controls.Add(this.testButton);
            this.Controls.Add(this.customOptionsBox);
            this.Controls.Add(this.stopButton);
            this.Controls.Add(this.startButton);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.modeSelectorBox);
            this.ForeColor = System.Drawing.Color.White;
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
            this.Name = "Main";
            this.Text = "IUBWM";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.modeSelectorBox.ResumeLayout(false);
            this.modeSelectorBox.PerformLayout();
            this.customOptionsBox.ResumeLayout(false);
            this.customOptionsBox.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.GroupBox modeSelectorBox;
        private System.Windows.Forms.RadioButton mode1Lane;
        private System.Windows.Forms.RadioButton modeCustom;
        private System.Windows.Forms.RadioButton modeField;
        private System.Windows.Forms.RadioButton modeMixing;
        private System.Windows.Forms.RadioButton modeWheat;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button startButton;
        private System.Windows.Forms.Button stopButton;
        private System.Windows.Forms.GroupBox customOptionsBox;
        private System.Windows.Forms.CheckBox checkBox2;
        private System.Windows.Forms.CheckBox checkBox1;
        private System.Windows.Forms.ComboBox comboBox1;
        private System.Windows.Forms.CheckBox checkBox4;
        private System.Windows.Forms.CheckBox checkBox3;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Button testButton;
    }
}

