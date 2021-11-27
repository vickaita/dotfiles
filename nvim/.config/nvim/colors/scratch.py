def test_fn(x: int, y: str) -> int:
    if True:
        return x * len(y)

class Foo:
    x: int
    y: str

    def __init__(self, a: int, b: str):
        self.x = a
        self.y = b

    @staticmethod
    def calc():
        a = 5
        return 1 + a + 2


foo = Foo(3, "hello")

s = foo.y * foo.x
