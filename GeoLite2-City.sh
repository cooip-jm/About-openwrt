#GeoLite2-City.mmdb更新脚本
#!/bin/bash
VERSION=$(curl -s "https://api.github.com/repos/PrxyHunter/GeoLite2/releases?per_page=1&page=0"  \
 | grep tag_name  \
 | cut -d ":" -f2 \
 | sed 's/\"//g;s/\,//g;s/\ //g;s/v//')
echo  "获取到的版本:${VERSION}"
curl -Lo GeoLite2-City.mmdb "https://github.com/PrxyHunter/GeoLite2/releases/download/${VERSION}/GeoLite2-City.mmdb"
