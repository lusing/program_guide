# -*- coding: utf-8 -*-
"""只跑文本替换+校验（改名已完成，防 two_phase 二次执行）。"""
import importlib.util, sys
spec = importlib.util.spec_from_file_location('rn', 'tools/renumber.py')
m = importlib.util.module_from_spec(spec)
sys.argv = ['renumber.py']          # APPLY=False → import 期 two_phase 仅 dry 打印
spec.loader.exec_module(m)
m.APPLY = True
m.replace_texts()                    # 这次真写盘（text_files() 现取现 glob）
m.verify()
