# amex
Command-line access to American Express (UK)
Inspired by https://github.com/runpaint/natwest

## Summary

Unlike NatWest, the American Express (UK) webpage requires javascript to load
successfully, so rather than just scraping HTML it requires actually loading
a browser. This is currently done using the Watir gem, an implementation of
Selenium in ruby.

The need to load a browser and interact means the process is
a bit slow and unreliable at the moment. If you have any suggestions on speeding
this up/alternative data collection methods I'm all ears.

This is set to be headless (with the view the amex.rb file is included in
laycat/fin as a submodule), and requires Xvfb (and as a result, requires X to be
installed). For most Linux users this shouldn't be a problem, see your local
package manager. For others, it might be easier to run within a Docker
container, hence the Dockerfile.

I use laycat/fin on a regular basis to sync AmEx transactions, so I should pick
up interface changes/bugs fairly quickly, but pull requests are more than
welcome.

## Command line usage

````
am <command>
Commands:
transactions <start date> <end date> <account>
    Gets transactions between two dates for an account. Dates are parsed by ruby
    (so can be any format parsable by Date.parse), account is the 4 last digits
    credit card number.
````

e.g.
````
# bin/am transactions 2016-08-25 2016-08-30 1008
Please enter your username:
*******
Please enter your password:
******************
Transactions for account ending 1008, between 2016-08-25 and 2016-08-30
Date       Description                                                 Amount
2016-08-28 JOHN LEWIS AT HOME LONDON                                        83.05
2016-08-27 TESCO SELF SERVICE WOOLWICH                                      52.52
````

## Dockerfile usage

`docker build -t 'amex' .`

passing args doesn't work properly (yet), so load up a shell and invoke as you
would from command line normally, e.g.

````
% docker run -it amex bash
root@45adee3411d7:/amex# bin/am transactions 2016-08-25 2016-08-30 1008
Please enter your username:
*******
Please enter your password:
******************
Transactions for account ending 1008, between 2016-08-25 and 2016-08-30
Date       Description                                                 Amount
2016-08-28 JOHN LEWIS AT HOME LONDON                                        83.05
2016-08-27 TESCO SELF SERVICE WOOLWICH                                      52.52
root@45adee3411d7:/amex# exit
````
