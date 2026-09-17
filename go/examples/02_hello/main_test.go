package main

import "testing"

func TestGreet(t *testing.T) {
	if got, want := Greet("Go"), "你好，Go！"; got != want {
		t.Errorf("Greet(\"Go\") = %q, want %q", got, want)
	}
	if got, want := Greet(""), "你好，匿名者！"; got != want {
		t.Errorf("Greet(\"\") = %q, want %q", got, want)
	}
}

func TestShout(t *testing.T) {
	if got, want := Shout("hi"), "hi!!!"; got != want {
		t.Errorf("Shout(\"hi\") = %q, want %q", got, want)
	}
}
