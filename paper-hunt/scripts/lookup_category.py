#!/usr/bin/env python3
"""
arXiv 分类查询脚本

用途：根据分类代码从完整的 arxiv_categories.json 中提取详细信息
使用场景：AI 先读取精简版分类列表，确定分类代码后，用此脚本获取完整信息

使用方法：
    python3 lookup_category.py --categories cs.AI,cs.CL,cs.LG
    python3 lookup_category.py --categories "cs.AI, cs.CL" --output result.json
    python3 lookup_category.py --categories cs.AI --format markdown
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Optional


def load_categories(json_path: str) -> dict:
    """加载完整的分类数据"""
    with open(json_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def lookup_categories(data: dict, category_codes: list[str]) -> dict:
    """查询指定分类的详细信息"""
    result = {
        "queried_categories": {},
        "not_found": [],
        "keywords_combined": [],
        "domain_mappings": {}
    }
    
    all_keywords = set()
    categories_data = data.get("categories", {})
    domain_mappings = data.get("domain_mappings", {})
    
    for code in category_codes:
        code = code.strip()
        if code in categories_data:
            cat_info = categories_data[code]
            result["queried_categories"][code] = cat_info
            # 收集关键词
            all_keywords.update(cat_info.get("keywords", []))
        else:
            result["not_found"].append(code)
    
    result["keywords_combined"] = list(all_keywords)
    
    # 查找相关的领域映射
    for domain, mappings in domain_mappings.items():
        for code in category_codes:
            if code in mappings:
                if domain not in result["domain_mappings"]:
                    result["domain_mappings"][domain] = mappings
                break
    
    return result


def format_output(result: dict, format_type: str) -> str:
    """格式化输出结果"""
    if format_type == "json":
        return json.dumps(result, indent=2, ensure_ascii=False)
    
    elif format_type == "markdown":
        lines = ["# arXiv 分类查询结果\n"]
        
        # 分类详情
        lines.append("## 分类详情\n")
        for code, info in result["queried_categories"].items():
            lines.append(f"### {code} - {info.get('name', 'N/A')}\n")
            lines.append(f"- **全名**：{info.get('full_name', 'N/A')}")
            lines.append(f"- **描述**：{info.get('description', 'N/A')}")
            lines.append(f"- **关键词**：{', '.join(info.get('keywords', []))}")
            lines.append("")
        
        # 合并的关键词
        if result["keywords_combined"]:
            lines.append("## 合并关键词\n")
            lines.append(", ".join(result["keywords_combined"]))
            lines.append("")
        
        # 相关领域映射
        if result["domain_mappings"]:
            lines.append("## 相关领域映射\n")
            for domain, mappings in result["domain_mappings"].items():
                lines.append(f"- **{domain}**：{', '.join(mappings)}")
            lines.append("")
        
        # 未找到的分类
        if result["not_found"]:
            lines.append("## 未找到的分类\n")
            lines.append(", ".join(result["not_found"]))
        
        return "\n".join(lines)
    
    elif format_type == "simple":
        lines = []
        for code, info in result["queried_categories"].items():
            keywords = ", ".join(info.get("keywords", [])[:5])  # 只显示前5个
            lines.append(f"{code}: {info.get('name', 'N/A')}")
            lines.append(f"  Keywords: {keywords}...")
        return "\n".join(lines)
    
    return json.dumps(result, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(
        description="查询 arXiv 分类的详细信息",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例：
    python3 lookup_category.py --categories cs.AI,cs.CL,cs.LG
    python3 lookup_category.py --categories "cs.AI, cs.CL" --output result.json
    python3 lookup_category.py --categories cs.AI --format markdown
        """
    )
    
    parser.add_argument(
        "--categories", "-c",
        type=str,
        required=True,
        help="要查询的分类代码，用逗号分隔（如：cs.AI,cs.CL,cs.LG）"
    )
    
    parser.add_argument(
        "--output", "-o",
        type=str,
        default=None,
        help="输出文件路径（默认输出到标准输出）"
    )
    
    parser.add_argument(
        "--format", "-f",
        type=str,
        choices=["json", "markdown", "simple"],
        default="json",
        help="输出格式：json（默认）、markdown、simple"
    )
    
    parser.add_argument(
        "--json-file",
        type=str,
        default=None,
        help="完整分类 JSON 文件路径（默认使用同目录下的 arxiv_categories.json）"
    )
    
    parser.add_argument(
        "--keywords-only",
        action="store_true",
        help="只输出合并后的关键词列表"
    )
    
    args = parser.parse_args()
    
    # 确定 JSON 文件路径
    if args.json_file:
        json_path = args.json_file
    else:
        json_path = str(Path(__file__).parent / "arxiv_categories.json")
    
    # 加载数据
    try:
        data = load_categories(json_path)
    except FileNotFoundError:
        print(f"错误：找不到分类文件 {json_path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"错误：JSON 解析失败 - {e}", file=sys.stderr)
        sys.exit(1)
    
    # 解析分类代码
    category_codes = [c.strip() for c in args.categories.split(",")]
    
    # 查询分类
    result = lookup_categories(data, category_codes)
    
    # 只输出关键词
    if args.keywords_only:
        output = ", ".join(result["keywords_combined"])
    else:
        output = format_output(result, args.format)
    
    # 输出结果
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output)
        print(f"结果已保存到 {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
