# Ruby Evaluation

This projects has been created and maintained during my Bachelor thesis and aims for a **reproducible** and **broad** evaluation of ruby interpreters.

Currently, there are two kind of comparisons:

* Plain Ruby-Script execution times
* Benchmarking curl requests against real-world applications

## Prerequisites

Despite from configuring `interpreters.json`, `applications.json`, installing and bundling the rubies + setting up/migrating the application data, there are no prerequisites. ;-)

Ok, now seriously
- Install rbenv and update ruby-build: `cd "$(rbenv root)"/plugins/ruby-build && git pull`
- Install mri-1.9.3: `rbenv install   1.9.3-p551`
- Install mri-2.3.3: `rbenv install   2.3.3`
- Install jruby-1.7.27: `rbenv install jruby-1.7.27`
- Install jruby-9.1.13: `rbenv install jruby-9.1.13.0`
- [Install truffleruby](https://makandracards.com/ruby-interpreter/47581-truffleruby)

Now that you have every interpreter installed, make sure that they have the bundler gem installed (e.g.: `rbenv shell 1.9.3; gem install bundler`). To install gems required by this programm and the tested scripts, run `bundle` and `./tcompare --bundle` (in this order).

Note: Keep in mind that this script is executed by a ruby interpreter as well! Look at the `.ruby-version` file to see which one it is. 

Additional script requirements:

- Install gnuplot: `sudo apt-get install gnuplot gnuplot-x11 gnuplot-doc`
//- Install rmagick: `sudo apt-get install imagemagick libmagickwand-dev`
//- Install gmp: `sudo apt-get install libgmp3-dev`

## T-Compare (Ruby Script comparison)

`interpreters.json` defines, which rubies are being compared. You have to install every of them using `rbenv`. The so called `base interpreter` is compared using the _Students t-test_ with every of the `versus` interpreters.

The file `scripts.json` defines a list of scripts that are evaluated with specified warmup iterations, trials etc. You can gladly add your own, best by first having a look at the other examples. Test results are stored in `results/script/<test name>/` and will be overwritten each time you re-run them. There are CSVs for every T-test, outlines (OS, script setup, runtime,..) as well as summarized results. Oh, and don't forget to look at the shiny plots.

* First, run `tcompare --bundle` to bundle every listed interpreter
* Then, run `tcompare --test-all` to run all tests on your machine or
* `tcompare --test-regex fannkuch` to run only tests including `fannkuch` in their filename
* See `tcompare --help` for a complete list

## T-Profile (Real application comparison)

This modus is configured by the `applications.json` setup file. For each version that you want to compare, clone your application in `../real-applications/<your_app>_<e.g 1_8_7>` and make sure it runs with e.g. Ruby `1.8.7`. Repeat.

Next, launch your application on `localhost:3000` and find Views / Form submissions / something that you want to measure. Open your Network panel in Chrome (`ctrl`+`shift`+`i`), click on the action and wait for it to load. Then, right click on it (mostly the upper most request) and select `Copy` -> `Copy as cURL`. 

Create a new View in your `applications.json` with a custom name, and paste the above to the `curl_command`. Paste it again at [CurlToAB](http://curltoab.com/) and copy the contents to `ab_payload`. **Caution: Leave out every flags, e.g. `ab -n 10 -c 1 -C `**.

Hint: Make sure you have passenger installed on every ruby version you compare.

Now your are ready to go: `./tcompare test-applications`! Your results and plot live in `results/applications/<appname>/`.


-----

Michael Leimstädtner, 2017 - 2018

Feel free to use
