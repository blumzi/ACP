﻿
namespace WiseWeatherSetup
{
    partial class Form
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
            this.components = new System.ComponentModel.Container();
            this.label1 = new System.Windows.Forms.Label();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.buttonTest = new System.Windows.Forms.Button();
            this.textBoxServerPort = new System.Windows.Forms.TextBox();
            this.textBoxServerAddress = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.checkBoxLocalWeatherIsReliable = new System.Windows.Forms.CheckBox();
            this.buttonOk = new System.Windows.Forms.Button();
            this.buttonCancel = new System.Windows.Forms.Button();
            this.label4 = new System.Windows.Forms.Label();
            this.labelMachine = new System.Windows.Forms.Label();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.label8 = new System.Windows.Forms.Label();
            this.textBoxTeleParkingDec = new System.Windows.Forms.TextBox();
            this.label7 = new System.Windows.Forms.Label();
            this.textBoxTeleAltLimit = new System.Windows.Forms.TextBox();
            this.label6 = new System.Windows.Forms.Label();
            this.textBoxTeleParkingHA = new System.Windows.Forms.TextBox();
            this.label5 = new System.Windows.Forms.Label();
            this.checkBoxMonitoringEnabled = new System.Windows.Forms.CheckBox();
            this.toolTip1 = new System.Windows.Forms.ToolTip(this.components);
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.label10 = new System.Windows.Forms.Label();
            this.textBoxDomeHomePosition = new System.Windows.Forms.TextBox();
            this.label9 = new System.Windows.Forms.Label();
            this.label11 = new System.Windows.Forms.Label();
            this.groupBox1.SuspendLayout();
            this.groupBox2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.label1.AutoSize = true;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.Location = new System.Drawing.Point(44, 19);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(195, 20);
            this.label1.TabIndex = 0;
            this.label1.Text = "Wise components for ACP";
            this.label1.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.buttonTest);
            this.groupBox1.Controls.Add(this.textBoxServerPort);
            this.groupBox1.Controls.Add(this.textBoxServerAddress);
            this.groupBox1.Controls.Add(this.label3);
            this.groupBox1.Controls.Add(this.label2);
            this.groupBox1.Controls.Add(this.checkBoxLocalWeatherIsReliable);
            this.groupBox1.ForeColor = System.Drawing.Color.DarkOrange;
            this.groupBox1.Location = new System.Drawing.Point(12, 133);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(248, 133);
            this.groupBox1.TabIndex = 1;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = " ASCOM SafeToOperate service ";
            // 
            // buttonTest
            // 
            this.buttonTest.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(64)))), ((int)(((byte)(64)))), ((int)(((byte)(64)))));
            this.buttonTest.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.buttonTest.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(176)))), ((int)(((byte)(161)))), ((int)(((byte)(142)))));
            this.buttonTest.Location = new System.Drawing.Point(172, 22);
            this.buttonTest.Name = "buttonTest";
            this.buttonTest.Size = new System.Drawing.Size(61, 55);
            this.buttonTest.TabIndex = 4;
            this.buttonTest.Text = "Test";
            this.buttonTest.UseVisualStyleBackColor = false;
            this.buttonTest.Click += new System.EventHandler(this.buttonTest_Click);
            // 
            // textBoxServerPort
            // 
            this.textBoxServerPort.Location = new System.Drawing.Point(64, 60);
            this.textBoxServerPort.Margin = new System.Windows.Forms.Padding(5, 3, 3, 3);
            this.textBoxServerPort.Name = "textBoxServerPort";
            this.textBoxServerPort.Size = new System.Drawing.Size(68, 20);
            this.textBoxServerPort.TabIndex = 3;
            // 
            // textBoxServerAddress
            // 
            this.textBoxServerAddress.ForeColor = System.Drawing.SystemColors.WindowText;
            this.textBoxServerAddress.Location = new System.Drawing.Point(64, 25);
            this.textBoxServerAddress.Margin = new System.Windows.Forms.Padding(5, 3, 3, 3);
            this.textBoxServerAddress.Name = "textBoxServerAddress";
            this.textBoxServerAddress.Size = new System.Drawing.Size(68, 20);
            this.textBoxServerAddress.TabIndex = 2;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(32, 64);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(29, 13);
            this.label3.TabIndex = 1;
            this.label3.Text = "Port:";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(13, 29);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(48, 13);
            this.label2.TabIndex = 0;
            this.label2.Text = "Address:";
            // 
            // checkBoxLocalWeatherIsReliable
            // 
            this.checkBoxLocalWeatherIsReliable.AutoSize = true;
            this.checkBoxLocalWeatherIsReliable.Location = new System.Drawing.Point(19, 95);
            this.checkBoxLocalWeatherIsReliable.Name = "checkBoxLocalWeatherIsReliable";
            this.checkBoxLocalWeatherIsReliable.Size = new System.Drawing.Size(210, 30);
            this.checkBoxLocalWeatherIsReliable.TabIndex = 2;
            this.checkBoxLocalWeatherIsReliable.Text = "Use the local weather station when the\r\nASCOM service is not accessible";
            this.checkBoxLocalWeatherIsReliable.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.checkBoxLocalWeatherIsReliable.UseVisualStyleBackColor = true;
            // 
            // buttonOk
            // 
            this.buttonOk.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(64)))), ((int)(((byte)(64)))), ((int)(((byte)(64)))));
            this.buttonOk.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.buttonOk.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(176)))), ((int)(((byte)(161)))), ((int)(((byte)(142)))));
            this.buttonOk.Location = new System.Drawing.Point(62, 460);
            this.buttonOk.Name = "buttonOk";
            this.buttonOk.Size = new System.Drawing.Size(71, 32);
            this.buttonOk.TabIndex = 5;
            this.buttonOk.Text = "Ok";
            this.buttonOk.UseVisualStyleBackColor = false;
            this.buttonOk.Click += new System.EventHandler(this.buttonOk_Click);
            // 
            // buttonCancel
            // 
            this.buttonCancel.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(64)))), ((int)(((byte)(64)))), ((int)(((byte)(64)))));
            this.buttonCancel.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.buttonCancel.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(176)))), ((int)(((byte)(161)))), ((int)(((byte)(142)))));
            this.buttonCancel.Location = new System.Drawing.Point(150, 460);
            this.buttonCancel.Name = "buttonCancel";
            this.buttonCancel.Size = new System.Drawing.Size(71, 32);
            this.buttonCancel.TabIndex = 6;
            this.buttonCancel.Text = "Cancel";
            this.buttonCancel.UseVisualStyleBackColor = false;
            this.buttonCancel.Click += new System.EventHandler(this.buttonCancel_Click);
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(61, 101);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(87, 13);
            this.label4.TabIndex = 7;
            this.label4.Text = "Current machine:";
            // 
            // labelMachine
            // 
            this.labelMachine.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(176)))), ((int)(((byte)(161)))), ((int)(((byte)(142)))));
            this.labelMachine.Location = new System.Drawing.Point(157, 101);
            this.labelMachine.Name = "labelMachine";
            this.labelMachine.Size = new System.Drawing.Size(90, 13);
            this.labelMachine.TabIndex = 8;
            // 
            // groupBox2
            // 
            this.groupBox2.Controls.Add(this.label8);
            this.groupBox2.Controls.Add(this.textBoxTeleParkingDec);
            this.groupBox2.Controls.Add(this.label7);
            this.groupBox2.Controls.Add(this.textBoxTeleAltLimit);
            this.groupBox2.Controls.Add(this.label6);
            this.groupBox2.Controls.Add(this.textBoxTeleParkingHA);
            this.groupBox2.Controls.Add(this.label5);
            this.groupBox2.Controls.Add(this.checkBoxMonitoringEnabled);
            this.groupBox2.ForeColor = System.Drawing.Color.DarkOrange;
            this.groupBox2.Location = new System.Drawing.Point(12, 272);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(248, 113);
            this.groupBox2.TabIndex = 9;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "Telescope settings ";
            // 
            // label8
            // 
            this.label8.AutoSize = true;
            this.label8.Location = new System.Drawing.Point(98, 52);
            this.label8.Name = "label8";
            this.label8.Size = new System.Drawing.Size(46, 13);
            this.label8.TabIndex = 10;
            this.label8.Text = "Parking:";
            // 
            // textBoxTeleParkingDec
            // 
            this.textBoxTeleParkingDec.ForeColor = System.Drawing.SystemColors.WindowText;
            this.textBoxTeleParkingDec.Location = new System.Drawing.Point(172, 79);
            this.textBoxTeleParkingDec.Margin = new System.Windows.Forms.Padding(5, 3, 3, 3);
            this.textBoxTeleParkingDec.Name = "textBoxTeleParkingDec";
            this.textBoxTeleParkingDec.Size = new System.Drawing.Size(61, 20);
            this.textBoxTeleParkingDec.TabIndex = 9;
            // 
            // label7
            // 
            this.label7.AutoSize = true;
            this.label7.Location = new System.Drawing.Point(141, 83);
            this.label7.Name = "label7";
            this.label7.Size = new System.Drawing.Size(30, 13);
            this.label7.TabIndex = 8;
            this.label7.Text = "Dec:";
            // 
            // textBoxTeleAltLimit
            // 
            this.textBoxTeleAltLimit.ForeColor = System.Drawing.SystemColors.WindowText;
            this.textBoxTeleAltLimit.Location = new System.Drawing.Point(172, 20);
            this.textBoxTeleAltLimit.Margin = new System.Windows.Forms.Padding(5, 3, 3, 3);
            this.textBoxTeleAltLimit.Name = "textBoxTeleAltLimit";
            this.textBoxTeleAltLimit.Size = new System.Drawing.Size(61, 20);
            this.textBoxTeleAltLimit.TabIndex = 7;
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.Location = new System.Drawing.Point(129, 24);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(42, 13);
            this.label6.TabIndex = 6;
            this.label6.Text = "Alt limit:";
            // 
            // textBoxTeleParkingHA
            // 
            this.textBoxTeleParkingHA.ForeColor = System.Drawing.SystemColors.WindowText;
            this.textBoxTeleParkingHA.Location = new System.Drawing.Point(172, 49);
            this.textBoxTeleParkingHA.Margin = new System.Windows.Forms.Padding(5, 3, 3, 3);
            this.textBoxTeleParkingHA.Name = "textBoxTeleParkingHA";
            this.textBoxTeleParkingHA.Size = new System.Drawing.Size(61, 20);
            this.textBoxTeleParkingHA.TabIndex = 5;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.Location = new System.Drawing.Point(146, 53);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(25, 13);
            this.label5.TabIndex = 4;
            this.label5.Text = "HA:";
            // 
            // checkBoxMonitoringEnabled
            // 
            this.checkBoxMonitoringEnabled.AutoSize = true;
            this.checkBoxMonitoringEnabled.Location = new System.Drawing.Point(19, 44);
            this.checkBoxMonitoringEnabled.Name = "checkBoxMonitoringEnabled";
            this.checkBoxMonitoringEnabled.Size = new System.Drawing.Size(74, 30);
            this.checkBoxMonitoringEnabled.TabIndex = 3;
            this.checkBoxMonitoringEnabled.Text = "Enable\r\nmonitoring";
            this.checkBoxMonitoringEnabled.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.toolTip1.SetToolTip(this.checkBoxMonitoringEnabled, "When enabled, the weather service will also monitor the\r\ntelescope.  If its altit" +
        "ude goes below the limit it will be\r\nparked at the configured parking position");
            this.checkBoxMonitoringEnabled.UseVisualStyleBackColor = true;
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.label10);
            this.groupBox3.Controls.Add(this.textBoxDomeHomePosition);
            this.groupBox3.Controls.Add(this.label9);
            this.groupBox3.ForeColor = System.Drawing.Color.DarkOrange;
            this.groupBox3.Location = new System.Drawing.Point(12, 391);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(248, 53);
            this.groupBox3.TabIndex = 10;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = " Dome settings ";
            // 
            // label10
            // 
            this.label10.AutoSize = true;
            this.label10.Location = new System.Drawing.Point(135, 23);
            this.label10.Name = "label10";
            this.label10.Size = new System.Drawing.Size(28, 13);
            this.label10.TabIndex = 10;
            this.label10.Text = "deg.";
            // 
            // textBoxDomeHomePosition
            // 
            this.textBoxDomeHomePosition.ForeColor = System.Drawing.SystemColors.WindowText;
            this.textBoxDomeHomePosition.Location = new System.Drawing.Point(64, 19);
            this.textBoxDomeHomePosition.Margin = new System.Windows.Forms.Padding(5, 3, 3, 3);
            this.textBoxDomeHomePosition.Name = "textBoxDomeHomePosition";
            this.textBoxDomeHomePosition.Size = new System.Drawing.Size(68, 20);
            this.textBoxDomeHomePosition.TabIndex = 9;
            this.textBoxDomeHomePosition.TextAlign = System.Windows.Forms.HorizontalAlignment.Center;
            // 
            // label9
            // 
            this.label9.AutoSize = true;
            this.label9.Location = new System.Drawing.Point(23, 23);
            this.label9.Name = "label9";
            this.label9.Size = new System.Drawing.Size(38, 13);
            this.label9.TabIndex = 8;
            this.label9.Text = "Home:";
            // 
            // label11
            // 
            this.label11.Location = new System.Drawing.Point(31, 39);
            this.label11.Name = "label11";
            this.label11.Size = new System.Drawing.Size(210, 42);
            this.label11.TabIndex = 11;
            this.label11.Text = "Configuration of some Wise-specific\r\ncomponents in ACP.";
            this.label11.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // Form
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(26)))), ((int)(((byte)(22)))), ((int)(((byte)(16)))));
            this.ClientSize = new System.Drawing.Size(278, 504);
            this.Controls.Add(this.label11);
            this.Controls.Add(this.groupBox3);
            this.Controls.Add(this.groupBox2);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.labelMachine);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.buttonCancel);
            this.Controls.Add(this.buttonOk);
            this.Controls.Add(this.label1);
            this.ForeColor = System.Drawing.Color.DarkOrange;
            this.Name = "Form";
            this.Text = "Wise4ACP Setup";
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.groupBox2.ResumeLayout(false);
            this.groupBox2.PerformLayout();
            this.groupBox3.ResumeLayout(false);
            this.groupBox3.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.Button buttonTest;
        private System.Windows.Forms.TextBox textBoxServerPort;
        private System.Windows.Forms.TextBox textBoxServerAddress;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.CheckBox checkBoxLocalWeatherIsReliable;
        private System.Windows.Forms.Button buttonOk;
        private System.Windows.Forms.Button buttonCancel;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label labelMachine;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.TextBox textBoxTeleParkingDec;
        private System.Windows.Forms.Label label7;
        private System.Windows.Forms.TextBox textBoxTeleAltLimit;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.TextBox textBoxTeleParkingHA;
        private System.Windows.Forms.Label label5;
        private System.Windows.Forms.CheckBox checkBoxMonitoringEnabled;
        private System.Windows.Forms.ToolTip toolTip1;
        private System.Windows.Forms.Label label8;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.Label label10;
        private System.Windows.Forms.TextBox textBoxDomeHomePosition;
        private System.Windows.Forms.Label label9;
        private System.Windows.Forms.Label label11;
    }
}

