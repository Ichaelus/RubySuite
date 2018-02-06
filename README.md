# Ruby Evaluation

This projects resulted from a Bachelor thesis and aims to be a reproducible evaluation of ruby interpreters like MRI, JRuby, TruffleRuby and others. Graphs, warmup time, Students t-test, and separate-thread-execution included.

Currently, there are two kind of comparisons:

* Run simple Ruby-Scripts several times and verify the statistical significance of the execution time variance 
* Benchmark real rails applications by evaluating the serving speed of various HTTP requests. Request concurrency can be specified.

## Prerequisites

There is quite a lot to do to make use of every feature, but for a start running `git clone git@github.com:Ichaelus/RubySuite.git` and configuring  `interpreters.json` might do the trick. It controls which interpreters are evaluated (in relation to a ground truth called _base_) based on the [_unpaired Students t-test_](https://en.wikipedia.org/wiki/Student%27s_t-test). For each entry, you can specify:

* A **name**, e.g. `mri 1.8.7`, used internally to plot graphs and distinguish interpreters.
* An **rbenv interpreter name**, e.g. `1.8.7`.  Make sure it is installed on your local machine by calling `rbenv list`.
* (optional) **Environment parameters**, e.g. `env foo=true`. This can be used to control special interpreter behavior.
* (optional) **Interpreter parameters**, e.g. `--jvm.server`. They are passed to the interpeter upon VM startup.

As a result the following command* is executed to evaluate the script `mandelbrot.rb` (an example):
```
rbenv shell 1.8.7 && env foo=true ruby --jvm.server -S mandelbrot.rb
```

* Some details are abstracted, but you might not choose to care about that.

A step by step guide to get the default list of interpeters running:

- Install [rbenv](https://github.com/rbenv/rbenv) and update [ruby-build](https://github.com/rbenv/ruby-build): `cd "$(rbenv root)"/plugins/ruby-build && git pull`
- For every interpreter of your choice below, install it and run `rbenv shell <interpreter> && gem install bundler` and `./tcompare --bundle` inside your cloned _RubySuite_ folder
  - Install [mri](https://github.com/ruby/ruby)-1.9.3: `rbenv install 1.9.3-p551`
  - Install mri-2.3.3: `rbenv install 2.3.3`
  - Install [Rubinius](https://github.com/rubinius/rubinius) 3.84 `rbenv install rbx-3.84`
  - [Install Ruby + OMR 2.4](https://github.com/rubyomr-preview/ruby/tree/ruby_2_4_omr)
  - [Install RTL-MJIT](https://github.com/vnmakarov/ruby/tree/rtl_mjit_branch)
  - Install [jruby](https://github.com/jruby/jruby)-1.7.27: `rbenv install jruby-1.7.27`
  - Install jruby-9.1.13: `rbenv install jruby-9.1.13.0`
  - [Install truffleruby](https://makandracards.com/ruby-interpreter/47581-truffleruby)
- And there is much more out there: Consider [Yarv-MJIT](https://github.com/k0kubun/yarv-mjit), [Topaz](https://github.com/topazproject/topaz) etc.

**Ok you came far already, don't give up now.**

Now that you have every interpreter installed along with the [bundler](https://github.com/bundler/bundler) gem, the last missing piece of the puzzle is an additional script requirement:

- [gnuplot](http://www.gnuplot.info/) is required to render fancy plots: `sudo apt-get install gnuplot gnuplot-x11 gnuplot-doc`

**Note: Keep in mind that this script is executed by a ruby interpreter as well! Look at the `.ruby-version` file to see which one it is.**


## T-Compare (Ruby Script comparison)

It's time to evaluate! Run `./tcompare --help` at any time to peek at the list of commands the suite provides for you. I'll list a few for you, the leading `./` :

```
./tcompare --bundle # Bundles every listed interpreter with script-specific dependencies. (Experimental)
./tcompare --test-scripts # A complete evaluation of the defined test scripts (*)
./tcompare --test-scripts-regex fannkuch` # Evaluate only scripts including `fannkuch` in their filename
./tcompare --help # A complete (and up-to-date) list of commands
```

(*) The file `scripts.json` defines a list of scripts that are evaluated with specified warmup iterations, trials etc. You can gladly add your own, best by first having a look at the other examples. Test results are stored in `results/script/<test name>/` and will be overwritten each time you re-run them. There are CSVs for every T-test, outlines (OS, script setup, runtime,..) as well as summarized results. Oh, and don't forget to look at the shiny plots.

## T-Profile (Real application comparison)

This modus is configured by the `applications.json` setup file. For each version that you want to compare, clone your application in `../real-applications/<your_app>_<e.g 1_8_7>` and make sure it runs with e.g. Ruby `1.8.7`. Repeat.

Next, launch your application on `localhost:3000` and find Views / Form submissions / something that you want to measure. Open your Network panel in Chrome (`ctrl`+`shift`+`i`), click on the action and wait for it to load. Then, right click on it (mostly the upper most request) and select `Copy` -> `Copy as cURL`. 

Create a new View in your `applications.json` with a custom name, and paste the above to the `curl_command`. Paste it again at [CurlToAB](http://curltoab.com/) and copy the contents to `ab_payload`. **Caution: Leave out every flags, e.g. `ab -n 10 -c 1 -C `**.

Hint: Make sure you have passenger installed on every ruby version you compare.

Now your are ready to go: `./tcompare test-applications`! Your results and plot live in `results/applications/<appname>/`.


-----

Michael Leimstädtner, 2017 - 2018

Feel free to use
