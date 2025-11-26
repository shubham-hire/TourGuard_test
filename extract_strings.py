import re, pathlib
text = pathlib.Path('Admin_Pannel/reference.js').read_text(encoding='utf8', errors='ignore')
strings = re.findall(r"[A-Za-z0-9][A-Za-z0-9\-\s&%:,\.\/\u2022]+", text)
for s in strings:
    if len(s) > 25 and 'http' not in s:
        print(s.strip())
