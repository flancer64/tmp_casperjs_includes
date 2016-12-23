# tmp_casperjs_includes

This is code for the "casperjs test" options [sample](https://gist.github.com/n1k0/3813361).

The "--include" option does not act as expected (*will include the ... files before each test file execution*). Actually these files are included once and before _pre_ files.

I have added comment to the begin of the `inc.js`:

```javascript
casper.echo("Hey, I should be included before each test file.");
```

.. then run command:

```bash
$ ./node_modules/casperjs/bin/casperjs test tests/ --pre=pre.js --includes=inc.js --post=post.js
```

... and have this output:

```
Hey, I should be included before each test file.
Test file: /home/alex/work/github/tmp_casperjs_includes/pre.js                  
Hey, I'm executed before the suite.
Test file: /home/alex/work/github/tmp_casperjs_includes/tests/test1.js          
# this is test 1
Hi, I've been included.
PASS Subject is strictly true
Test file: /home/alex/work/github/tmp_casperjs_includes/tests/test2.js          
# this is test 2
Hi, I've been included.
PASS Subject is strictly true
Test file: /home/alex/work/github/tmp_casperjs_includes/post.js                 
Hey, I'm executed after the suite.
PASS 2 tests executed in 0.061s, 2 passed, 0 failed, 0 dubious, 0 skipped.   
```

There is one only message "*Hey, I should be included before each test file.*"