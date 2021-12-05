import {somethingElse} from "foo";

function apple(banana: string[]): number {
  return banana.length;
}

const boo = (x: number, y: string) => {
  if (apple(["cherry"])) {
    console.log("something")
  } else {
    somethingElse();
    const b = /abc/;
    const y = 6;
    let x = 100 + 200 * 300;
    x = 5;
  }
}

const a: number[] = [1, 2, 3];
a.map
