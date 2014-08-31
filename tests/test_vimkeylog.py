from vimkeylog import parse


def test_ignore_insert_mode():
    assert parse('iasd\1b') == []


def test_random_complex_example():
    assert parse('jjk:x\r:e\x80kb\x80kb') == ['j', 'j', 'k', '\r']
