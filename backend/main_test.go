package main

import "testing"

func TestSign(t *testing.T) {
	if got := sign("abc"); got != "900150983cd24fb0d6963f7d28e17f72" {
		t.Fatalf("sign=%s", got)
	}
}
