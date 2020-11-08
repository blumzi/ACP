using ACP;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

using Microsoft.Win32;
using System.Net;
using System.IO;
using System.Net.Http;
using Newtonsoft.Json;
using ASCOM.Utilities;

namespace WiseWeatherSetup
{
    public partial class Form : System.Windows.Forms.Form
    {
        private readonly string machine = Environment.MachineName;
        private const string settingsFile = "c:/Program Files (x86)/ACP Obs Control/WeatherComponents/WiseWeather.json";
        private Settings settings;
        private string _serverStatus;
        private Color _serverStatusColor;
        ASCOM.Utilities.Util ascomutil = new ASCOM.Utilities.Util();

        public Form()
        {
            InitializeComponent();

            try
            {
                using (StreamReader sr = File.OpenText(settingsFile))
                {
                    JsonSerializer serializer = new JsonSerializer();
                    settings = (Settings)serializer.Deserialize(sr, typeof(Settings));
                }
            } catch (Exception)
            {
                settings = new Settings()
                {
                    Saved = DateTime.MinValue,
                    Server = new Server { Address = "dome-pc", Port = 11111, },
                    Monitoring = new TelescopeMonitoring { Enabled = false, HourAngle = 0, Declination = 0 },
                    Reliable = false,
                };
            }

            Address = settings.Server.Address;
            Port = settings.Server.Port;
            Reliable = settings.Reliable;

            textBoxServerAddress.Text = Address;
            textBoxServerPort.Text = Port.ToString();
            checkBoxLocalWeatherIsReliable.Checked = Reliable;

            checkBoxMonitoringEnabled.Checked = settings.Monitoring.Enabled;
            textBoxAltLimit.Text = ascomutil.DegreesToDMS(settings.Monitoring.AltLimit);
            textBoxParkingHA.Text = ascomutil.DegreesToHMS(settings.Monitoring.HourAngle);
            textBoxParkingDec.Text = ascomutil.DegreesToDMS(settings.Monitoring.Declination);
            labelMachine.Text = machine;
        }

        public static string Address { get; set; }
        public UInt16 Port { get; set; }
        public bool Reliable { get; set; }

        private void buttonCancel_Click(object sender, EventArgs e)
        {
            Close();
        }

        private void buttonOk_Click(object sender, EventArgs e)
        {
            settings.Server.Address = textBoxServerAddress.Text.Trim();
            settings.Server.Port = Convert.ToUInt16(textBoxServerPort.Text.Trim());
            settings.Reliable = checkBoxLocalWeatherIsReliable.Checked;
            settings.Saved = DateTime.Now;
            settings.Monitoring.Enabled = checkBoxMonitoringEnabled.Checked;
            settings.Monitoring.AltLimit = ascomutil.DMSToDegrees(textBoxAltLimit.Text);
            settings.Monitoring.HourAngle = ascomutil.HMSToDegrees(textBoxParkingHA.Text);
            settings.Monitoring.Declination = ascomutil.DMSToDegrees(textBoxParkingDec.Text);

            File.WriteAllText(settingsFile, JsonConvert.SerializeObject(settings));
            Close();
        }

        private void buttonTest_Click(object sender, EventArgs e)
        {

            if (string.IsNullOrWhiteSpace(textBoxServerAddress.Text))
            {
                labelStatus.Text = "Null or empty Address";
                labelStatus.ForeColor = Color.Red;
                return;
            }
            string server = textBoxServerAddress.Text;

            if (string.IsNullOrWhiteSpace(textBoxServerPort.Text))
            {
                labelStatus.Text = "Null or empty Port";
                labelStatus.ForeColor = Color.Red;
                return;
            }
            UInt16 port = Convert.ToUInt16(textBoxServerPort.Text);

            string serverport = $"{server}:{port}";
            string url = $"http://{serverport}/server/v1/concurrency";

            using (var client = new WebClient())
            {
                try
                {
                    labelStatus.Text = "Connecting ASCOM server";
                    DateTime start = DateTime.Now;

                    client.DownloadDataCompleted += new DownloadDataCompletedEventHandler(onDataDownloadCompletion);
                    client.DownloadDataAsync(new Uri(url)); // GET to http://www.xxx.yyy.zzz/server/v1/concurrency
                    System.Threading.Thread.Sleep(500);
                    while (client.IsBusy)
                    {
                        if (DateTime.Now.Subtract(start).TotalMilliseconds > 500)
                        {
                            client.CancelAsync();
                            labelStatus.Text = "Connection timedout.";
                            labelStatus.ForeColor = Color.Red;
                            break;
                        }
                    }
                }
                catch (Exception ex)
                {
                    labelStatus.Text = $"Exception: {ex.Message}";
                    labelStatus.ForeColor = Color.Red;
                }
            }
        }
        
        private void onDataDownloadCompletion(object sender, DownloadDataCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                _serverStatus = "timedout";
                _serverStatusColor = Color.Red;
            }
            else if (e.Error != null)
            {
                _serverStatus = $"error: {e.Error}";
                _serverStatusColor = Color.Red;
            }
            else
            {
                string reply = ((byte[])e.Result).ToString();
                _serverStatus = reply;
                _serverStatusColor = Color.Green;
            }
            labelStatus.Text = $"Connection {_serverStatus}";
            labelStatus.ForeColor = _serverStatusColor;
        }
    }

    public class Server
    {
        public string Address;
        public ushort Port;
    };

    public class TelescopeMonitoring
    {
        public bool Enabled;
        public double AltLimit;
        public double HourAngle, Declination;
    }

    public class Settings
    {
        public DateTime Saved;
        public Server Server;
        public bool Reliable;
        public TelescopeMonitoring Monitoring;
    }
}
