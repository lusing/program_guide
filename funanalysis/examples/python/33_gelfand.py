import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
print("==== 33 gelfand (Python) ====")
D = np.diag([1.0, 2.0, 3.0])
print(f"Gelfand transform values = {np.diag(D)}")
assert np.abs(np.diag(D)).max() == 3.0
print("==== 33 gelfand END ====")
