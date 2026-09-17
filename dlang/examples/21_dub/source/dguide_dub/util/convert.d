module dguide_dub.util.convert;

double celsiusToF(double c) {
    return c * 9 / 5 + 32;
}

unittest {
    assert(celsiusToF(0) == 32);
    assert(celsiusToF(100) == 212);
}
