package main

import "testing"

func TestCToF(t *testing.T) {
	if got, want := CToF(100), Fahrenheit(212.0); got != want {
		t.Errorf("CToF(100) = %g, want %g", got, want)
	}
}

func TestClamp(t *testing.T) {
	cases := []struct {
		v, lo, hi, want int
	}{
		{150, 0, 100, 100},
		{-5, 0, 100, 0},
		{42, 0, 100, 42},
	}
	for _, c := range cases {
		if got := Clamp(c.v, c.lo, c.hi); got != c.want {
			t.Errorf("Clamp(%d, %d, %d) = %d, want %d", c.v, c.lo, c.hi, got, c.want)
		}
	}
}

func TestWeekdayString(t *testing.T) {
	if got, want := Wednesday.String(), "周三"; got != want {
		t.Errorf("Wednesday.String() = %q, want %q", got, want)
	}
}
