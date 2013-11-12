## Benchmarking
### How to run script
To start benchmarking please run:
`wget -N https://raw.github.com/benchmarky/bench_test/master/script.sh&&bash script.sh -e email@email.com -p PROVIDER -c PLAN -t all`
Please be sure to provide correct email since we'll send results to it.
For more information about script parameters please run the script with -h parameter:
```
$ bash script.sh -h
Usage: bash script.sh [ -h ] -e 'email@email.com' -p 'Hosting Company, Inc.' -c 'Awesome Plan' -t all [ -a ] [ -q ]
	-e - email
	-h - show this help
	-p - provider
	-c - tariff
	-t - which tests to run (comma-separated list (disk,unixbench,bandwidth) or all
	-a - don't public results
	-q - show less messages
```
