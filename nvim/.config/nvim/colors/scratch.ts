import { somethingElse } from "foo";

const curriedAdd = (a: number) => (b: number) => (c: number) => a + b + c;

function apple(banana: string[]): number {
  return banana.length;
}

const boo = (x: number, y: string) => {
  // NOTE: fix this
  // TODO: fix this
  // FIXME: fix this
  if (apple(["cherry"])) {
    console.log("something");
  } else {
    somethingElse();
    const b = /abc/;
    const y = 6;
    x = 100 + 200 * 300;
    x = 5;
    if (true || false) {
      let apple = 15;
    }
  }
};

const a: number[] = [1, 2, 3];
a.map();

class Point {
  constructor(public x: number, private y: number) {}

  isOrigin(): boolean {
    return this.x === 0 && this.y === 0;
  }
}
