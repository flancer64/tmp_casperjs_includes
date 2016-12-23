casper.echo("Hey, I should be included before each test file.");
casper.sayHi = function sayHi() {
    this.echo("Hi, I've been included.");
}