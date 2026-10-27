"""仅转换 CI 锁文件的国内镜像地址，保留依赖版本和内容校验值。"""

import re
import sys
from pathlib import Path


def prepare(path: Path) -> int:
    original = path.read_bytes()
    # 只匹配完整的 url 行，不改版本、sha256、SDK 约束或其它仓库地址。
    pattern = re.compile(
        rb'(?m)^([ \t]+url:[ \t]+)(["\']?)https://pub\.flutter-io\.cn/?\2([ \t]*\r?)$'
    )
    updated, count = pattern.subn(rb'\1"https://pub.dev"\3', original)
    if updated != original:
        path.write_bytes(updated)
    return count


if __name__ == '__main__':
    count = prepare(Path(sys.argv[1]) if len(sys.argv) > 1 else Path('pubspec.lock'))
    print(f'CI 包源转换完成：{count} 项；保留锁定版本和校验值。')
