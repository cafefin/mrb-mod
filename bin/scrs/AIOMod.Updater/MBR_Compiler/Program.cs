﻿using System;

namespace BoldinaRuns
{
    class Program
    {
        static void Main(string[] args)
        {
            string path = AppDomain.CurrentDomain.BaseDirectory;
            Environment.CurrentDirectory = (path);

            var sScript = "/AutoIt3ExecuteScript " + '"' + "AIOMod.Updater.au3" + '"';
            var sTmpFoo = "";
            for (int i = 0; i < args.Length; i++)
			{
                sTmpFoo = $"{args[i]}";
                sScript += " " + sTmpFoo.ToString();
            }
            // Console.WriteLine(sScript);

            System.Diagnostics.Process.Start("bin\\AutoIt3.exe", sScript);
        }

    }
}
