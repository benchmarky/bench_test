## [Benchmarky](http://benchmarky.com/) Linux Server Benchmark
### What is it?
This tool is a lightweight benchmarking script made for testing CPU, Disk (HDD or SSD) and Bandwidth performance in Linux servers. The tool is composed of simple and trusted open-source benchmarking suites.
### What will it do?
This benchmark will:
* Download and install packages necessary to run benchmark test (don't worry, it will clean up after)
* Download and run Unixbench, Disk and/or Bandwidth tests
* Upload tests results over to Benchmarky.com to see how it stacks up against others

### How to run script
To start benchmarking simply access your server's terminal and run: 
*(First replace the sections enclosed in apostrophe marks (') with your details. Please make sure to provide correct email since we'll send results to it after it is finished.)*

```bash
wget -N https://raw.github.com/benchmarky/bench_test/master/script.sh&&bash script.sh -e 'email@email.com' -p 'PROVIDER' -l 'PLAN NAME' -c 'TARIFF' -t all
```
Example:
```bash
wget -N https://raw.github.com/benchmarky/bench_test/master/script.sh&&bash script.sh -e 'email@email.com' -p 'Hostingcompany.com' -l 'Big Premium Plan with SSD and CentOS' -c '$24' -t all
```

### Noteworthy tips & comments:
* This script has been tested on Linux environments only, including Ubuntu, Debian, and CentOS.
* If possible, please pause any and all resource intensive services you are running such as databases, web server, etc. This will help improve the consistency of benchmark results.
* WARNING: You run this script at your own risk. Benchmarky accepts no responsibility for any damage this script may cause.

For a reference guide about script parameters please run the script with -h parameter, like the following example:

```bash
bash script.sh -h
```
It will return the following:
```
Usage: bash script.sh [ -h ] -e 'email@email.com' -p 'Hosting Company, Inc.' -c 'Awesome Plan' -t all [ -a ] [ -q ]
	-e - email
	-h - show this help
	-p - provider
	-l - plan
	-c - tariff (cost per month)
	-t - which tests to run (comma-separated list (disk,unixbench,bandwidth) or all
	-a - keep report private
	-q - show less messages
```
For more information about this and other benchmarking tools please check out our website and community at [http://benchmarky.com](http://benchmarky.com/) 
