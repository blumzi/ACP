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
        private readonly string machine = Environment.MachineName.ToLower();
        private const string settingsFile = "c:/Program Files (x86)/ACP Obs Control/WiseSettings.json";
        private readonly Settings settings;
        readonly ASCOM.Utilities.Util ascomutil = new ASCOM.Utilities.Util();

        Dictionary<string, Settings> defaultSettings = new Dictionary<string, Settings>() {
                { "c28-pc", new Settings {
                    Observatory = "C28",
                    WeatherStationIsReliable = true,
                    Server = new Server
                    {
                        Address = "dome-pc",
                        Port = 11111,
                    },
                    Telescope = new Telescope { MonitoringEnabled = true, AltLimit = 14.0, Declination = 45.0, HourAngle = 0.0, },
                    Dome = new Dome { HomePosition = 233.0 },
                } },

                { "c18-pc", new Settings {
                    Observatory = "C18",
                    WeatherStationIsReliable = false,
                    Server = new Server
                    {
                        Address = "dome-pc",
                        Port = 11111,
                    },
                    Telescope = new Telescope { MonitoringEnabled = true, AltLimit = 14.0, Declination = 45.0, HourAngle = 0.0, },
                    Dome = new Dome { HomePosition = 82.0 },
                } },

                { "dome-pc", new Settings {
                    Observatory = "Wise40",
                    WeatherStationIsReliable = false,
                    Server = new Server
                    {
                        Address = "127.0.0.1",
                        Port = 11111,
                    },
                    Telescope = new Telescope { MonitoringEnabled = false, AltLimit = 14.0, Declination = 66.0, HourAngle = 0.0, },
                    Dome = new Dome { HomePosition = 90.0 },
                } },
            };

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
            }
            catch (Exception)
            {
                Settings def = defaultSettings[machine];
                string serverAddress = (machine == "dome-pc") ? "127.0.0.1" : "dome-pc";

                settings = new Settings()
                {
                    Saved = DateTime.MinValue,
                    Server = new Server { Address = serverAddress, Port = 11111, },
                    Telescope = def.Telescope,
                    Dome = def.Dome,
                    WeatherStationIsReliable = def.WeatherStationIsReliable,
                };
            }

            Address = settings.Server.Address;
            Port = settings.Server.Port;
            Reliable = settings.WeatherStationIsReliable;

            textBoxServerAddress.Text = Address;
            textBoxServerPort.Text = Port.ToString();
            checkBoxLocalWeatherIsReliable.Checked = Reliable;

            checkBoxMonitoringEnabled.Checked = settings.Telescope.MonitoringEnabled;
            textBoxTeleAltLimit.Text = ascomutil.DegreesToDM(settings.Telescope.AltLimit);
            textBoxTeleParkingHA.Text = ascomutil.DegreesToHMS(settings.Telescope.HourAngle);
            textBoxTeleParkingDec.Text = ascomutil.DegreesToDMS(settings.Telescope.Declination);
            textBoxDomeHomePosition.Text = ascomutil.DegreesToDM(settings.Dome.HomePosition);
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
            settings.Observatory = defaultSettings[machine].Observatory;
            settings.Machine = machine;
            settings.Server.Address = textBoxServerAddress.Text.Trim();
            settings.Server.Port = Convert.ToUInt16(textBoxServerPort.Text.Trim());
            settings.WeatherStationIsReliable = checkBoxLocalWeatherIsReliable.Checked;
            settings.Saved = DateTime.Now;
            settings.Telescope.MonitoringEnabled = checkBoxMonitoringEnabled.Checked;
            settings.Telescope.AltLimit = ascomutil.DMSToDegrees(textBoxTeleAltLimit.Text);
            settings.Telescope.HourAngle = ascomutil.HMSToDegrees(textBoxTeleParkingHA.Text);
            settings.Telescope.Declination = ascomutil.DMSToDegrees(textBoxTeleParkingDec.Text);
            settings.Dome.HomePosition = ascomutil.DMSToDegrees(textBoxDomeHomePosition.Text);

            File.WriteAllText(settingsFile, JsonConvert.SerializeObject(settings, Formatting.Indented));
            Close();
        }

        public class ASCOMResponse
        {
            public string Value;
            public int ClientTransactionID;
            public int ServerTransactionID;
            public int ErrorNumber;
            public string ErrorMessage;
            public string DriverException;
        }

        private void buttonTest_Click(object sender, EventArgs e)
        {

            if (string.IsNullOrWhiteSpace(textBoxServerAddress.Text))
            {
                MessageBox.Show("Null or empty Address", "Bad setting", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            string server = textBoxServerAddress.Text;

            if (string.IsNullOrWhiteSpace(textBoxServerPort.Text))
            {
                MessageBox.Show("Null or empty Port", "Bad setting", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            UInt16 port = Convert.ToUInt16(textBoxServerPort.Text);

            string serverport = $"{server}:{port}";
            string url = $"http://{serverport}/server/v1/concurrency";

            using (var client = new WebClient())
            {
                try
                {
                    DateTime start = DateTime.Now;

                    client.DownloadDataCompleted += new DownloadDataCompletedEventHandler(onDataDownloadCompletion);
                    client.DownloadDataAsync(new Uri(url)); // GET to http://www.xxx.yyy.zzz/server/v1/concurrency
                    System.Threading.Thread.Sleep(500);
                    while (client.IsBusy)
                    {
                        if (DateTime.Now.Subtract(start).TotalMilliseconds > 500)
                        {
                            client.CancelAsync();
                            MessageBox.Show("Connection timedout.", "Communication error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                            break;
                        }
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Exception: {ex.Message}", "Communication error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
        
        private void onDataDownloadCompletion(object sender, DownloadDataCompletedEventArgs e)
        {
            if (e.Cancelled)
            {
                MessageBox.Show("Connection timedout.", "Communication error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            else if (e.Error != null)
            {
                MessageBox.Show($"Error: {e.Error}", "Communication error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            else
            {
                ASCOMResponse response = JsonConvert.DeserializeObject<ASCOMResponse>(System.Text.Encoding.UTF8.GetString(e.Result));

                if (response.ErrorNumber == 0 && response.DriverException == null)
                    MessageBox.Show($"Communication with the SafeToOperate service succeeded.", "Communication success", MessageBoxButtons.OK, MessageBoxIcon.Information);
                else
                    MessageBox.Show("Communication with the SafeToOperate service failed\n" + 
                        $"\tError: {response.ErrorMessage}\n" +
                        $"\tException: {response.DriverException}", "Communication failure", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }

    public class Server
    {
        public string Address;
        public ushort Port;
    };

    public class Telescope
    {
        public bool MonitoringEnabled;
        public double AltLimit;
        public double HourAngle, Declination;
    }

    public class Dome
    {
        public double HomePosition;
    }

    public class Settings
    {
        public DateTime Saved;
        public string Observatory;
        public string Machine;
        public Server Server;
        public bool WeatherStationIsReliable;
        public Telescope Telescope;
        public Dome Dome;
    }
}
