#!/usr/bin/env python3
"""Write each Shanghai script as .md (clean), .txt (clean) and _TTS.txt.

TTS rules (owner's standing preference): phonetic respelling only, lowercase,
no hyphens, no markup or brackets, [beat] becomes a paragraph break, years
spelled out. The clean scripts already spell every number out.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _clean import SCRIPTS  # noqa: E402

OUT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Longest keys first, so "Lyndon Neri" wins over "Neri".
RESPELL = {
    "Zhang Yuan's": "jahng yooen's", "Zhang Yuan": "jahng yooen", "Zhang Yong": "jahng yong",
    "shikumen": "shir koo mun", "Maoming": "mow ming",
    "Lyndon Neri": "lindon nairy", "Rossana Hu": "rozzahna hoo", "Neri and Hu": "nairy and hoo",
    "Hotung": "ho tung", "Jardine Matheson": "jardeen matthison", "Shaanxi": "shahn shee",
    "Mao Zedong": "mow dzuh dong", "Cihai": "tsuh hi", "Rong Zhai": "rong jie",
    "Jean-Georges Vongerichten": "zhahn zhorzh vonger ikten", "Jean-Georges": "zhahn zhorzh",
    "Mercato": "mer kahto", "Guangdong": "gwahng dong", "Pudong": "poo dong",
    "Tianping": "tyen ping", "Huaihai": "hwhy hi", "benbang": "bun bahng", "Wukang": "woo kahng",
    "Zhongshan": "jong shahn", "Yu Waitan": "yoo why tahn", "Xiamen": "shah mun", "Yanyu": "yen yoo",
    "Fujian": "foo jyen", "Hetian": "huh tyen", "Longyan": "long yen", "Heatherwick": "hether wick",
    "Taiyuan": "tie yooen", "Yongjia": "yong jyah", "Ahguang": "ah gwahng", "Siwei": "suh way",
    "Huqiu": "hoo cheeoh", "Huangpu": "hwahng poo", "Suzhou": "soo joe", "Yuanmingyuan": "yooen ming yooen",
    "Waibaidu": "why by doo", "bagua": "bah gwah", "Chipperfield": "chipper field",
    "PuLi": "poo lee", "Jing'an": "jing ahn", "Yan'an": "yen ahn", "Changde": "chahng duh",
    "Kume Sekkei": "koo meh sekkay", "Jaya": "jaya",
    "Schrager": "shray ger", "Schmitt": "shmit",
    "Sukhothai": "sook oh tie", "Weihai": "way hi", "terrazzo": "tuh rat so",
    "Longteng": "long tung", "Pompidou": "pom pee doo", "Macron": "mack ron", "Longhua": "long hwah",
    "Yuz": "yooz", "EDITION": "Edition",
    "Xin Rong Ji's": "shin rong jee's", "Xin Rong Ji": "shin rong jee", "Rong Fu Yan": "rong foo yen",
    "I. M. Pei": "eye em pay", "Pei": "pay", "Linhai": "lin hi", "Taizhou": "tie joe",
    "Zhejiang": "juh jyahng", "Nanyang": "nahn yahng",
    "Jiangning": "jyahng ning", "Sheji Gonghe": "shuh jee gong huh",
}
RE_RESPELL = re.compile(r"\b(?:" + "|".join(re.escape(k) for k in sorted(RESPELL, key=len, reverse=True)) + r")(?![A-Za-z])")


def tts(text):
    text = RE_RESPELL.sub(lambda m: RESPELL[m.group(0)], text)
    text = re.sub(r"\n*\[beat\]\n*", "\n\n", text)
    text = re.sub(r"(?<=\w)-(?=\w)", " ", text)            # no hyphens
    text = text.replace("&", "and")
    text = re.sub(r"[\[\]<>{}*_#`]", "", text)               # no markup or brackets
    assert not re.search(r"\d", text), "digit left in TTS text"
    return re.sub(r"\n{3,}", "\n\n", text).strip() + "\n"


def main():
    for num, slug, title, tts_title, body in SCRIPTS:
        base = f"shanghai_{num}_{slug.replace('-', '_')}"
        head = f"ATLAS · SHANGHAI · {num} · {title}\n---\n"
        clean = body.strip() + "\n"
        assert not re.search(r"\d", clean), f"{num}: digit in clean script"
        words = len(re.findall(r"[A-Za-z']+", clean.replace("[beat]", "")))
        with open(os.path.join(OUT, base + ".txt"), "w") as f:
            f.write(head + clean)
        with open(os.path.join(OUT, base + ".md"), "w") as f:
            f.write(f"# {title}\n\n*Atlas · Shanghai · {num} · ~{words} words, about "
                    f"{round(words / 150 * 60 / 10) * 10} seconds*\n\n---\n\n{clean}")
        with open(os.path.join(OUT, base + "_TTS.txt"), "w") as f:
            f.write(f"ATLAS · SHANGHAI · {num} · {tts_title}\n---\n" + tts(clean))
        print(f"{num} {words:4d} words  {base}")


if __name__ == "__main__":
    main()
