/**
 * Sub-Store 节点名称规范化器
 *
 * 根据节点名称中的可靠地区证据，将已识别节点改为“中文地区名 + 编号”。
 * 脚本只处理本地名称，不查询 IP、GeoIP 或远程接口，不删除节点，
 * 不改变节点顺序，也不修改名称以外的节点属性。
 *
 * 地区代码采用 ISO 3166-1。地区显示名和 alpha-3 映射根据 Unicode CLDR
 * 48.2.0（cldr-json 1aaabe99aa652d6f22ea488cf25baea46aa69b42）整理；
 * 常见城市和机场代码由本项目独立维护。
 */

/*
 * Unicode CLDR-derived region data is used under the following license:
 *
 * UNICODE LICENSE V3
 *
 * COPYRIGHT AND PERMISSION NOTICE
 *
 * Copyright © 2004-2026 Unicode, Inc.
 *
 * NOTICE TO USER: Carefully read the following legal agreement. BY
 * DOWNLOADING, INSTALLING, COPYING OR OTHERWISE USING DATA FILES, AND/OR
 * SOFTWARE, YOU UNEQUIVOCALLY ACCEPT, AND AGREE TO BE BOUND BY, ALL OF THE
 * TERMS AND CONDITIONS OF THIS AGREEMENT. IF YOU DO NOT AGREE, DO NOT
 * DOWNLOAD, INSTALL, COPY, DISTRIBUTE OR USE THE DATA FILES OR SOFTWARE.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of data files and any associated documentation (the "Data Files") or
 * software and any associated documentation (the "Software") to deal in the
 * Data Files or Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, and/or sell
 * copies of the Data Files or Software, and to permit persons to whom the
 * Data Files or Software are furnished to do so, provided that either (a)
 * this copyright and permission notice appear with all copies of the Data
 * Files or Software, or (b) this copyright and permission notice appear in
 * associated Documentation.
 *
 * THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
 * KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
 * THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS
 * INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR
 * CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
 * USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
 * TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THE DATA FILES OR SOFTWARE.
 *
 * Except as contained in this notice, the name of a copyright holder shall
 * not be used in advertising or otherwise to promote the sale, use or other
 * dealings in these Data Files or Software without prior written
 * authorization of the copyright holder.
 *
 * License source:
 * https://github.com/unicode-org/cldr-json/blob/main/cldr-json/cldr-core/LICENSE
 */

// Rows: ISO alpha-2, ISO alpha-3, Simplified Chinese name, English name,
// optional CLDR alternative names. Kept in one file so remote imports remain
// self-contained in every Sub-Store runtime.
const REGION_ROWS = [
  ['AD', 'AND', '安道尔', 'Andorra'],
  ['AE', 'ARE', '阿拉伯联合酋长国', 'United Arab Emirates'],
  ['AF', 'AFG', '阿富汗', 'Afghanistan'],
  ['AG', 'ATG', '安提瓜和巴布达', 'Antigua & Barbuda'],
  ['AI', 'AIA', '安圭拉', 'Anguilla'],
  ['AL', 'ALB', '阿尔巴尼亚', 'Albania'],
  ['AM', 'ARM', '亚美尼亚', 'Armenia'],
  ['AO', 'AGO', '安哥拉', 'Angola'],
  ['AQ', 'ATA', '南极洲', 'Antarctica'],
  ['AR', 'ARG', '阿根廷', 'Argentina'],
  ['AS', 'ASM', '美属萨摩亚', 'American Samoa'],
  ['AT', 'AUT', '奥地利', 'Austria'],
  ['AU', 'AUS', '澳大利亚', 'Australia'],
  ['AW', 'ABW', '阿鲁巴', 'Aruba'],
  ['AX', 'ALA', '奥兰群岛', 'Åland Islands'],
  ['AZ', 'AZE', '阿塞拜疆', 'Azerbaijan'],
  ['BA', 'BIH', '波斯尼亚和黑塞哥维那', 'Bosnia & Herzegovina', ['Bosnia']],
  ['BB', 'BRB', '巴巴多斯', 'Barbados'],
  ['BD', 'BGD', '孟加拉国', 'Bangladesh'],
  ['BE', 'BEL', '比利时', 'Belgium'],
  ['BF', 'BFA', '布基纳法索', 'Burkina Faso'],
  ['BG', 'BGR', '保加利亚', 'Bulgaria'],
  ['BH', 'BHR', '巴林', 'Bahrain'],
  ['BI', 'BDI', '布隆迪', 'Burundi'],
  ['BJ', 'BEN', '贝宁', 'Benin'],
  ['BL', 'BLM', '圣巴泰勒米', 'St. Barthélemy'],
  ['BM', 'BMU', '百慕大', 'Bermuda'],
  ['BN', 'BRN', '文莱', 'Brunei'],
  ['BO', 'BOL', '玻利维亚', 'Bolivia'],
  ['BQ', 'BES', '荷属加勒比区', 'Caribbean Netherlands'],
  ['BR', 'BRA', '巴西', 'Brazil'],
  ['BS', 'BHS', '巴哈马', 'Bahamas'],
  ['BT', 'BTN', '不丹', 'Bhutan'],
  ['BV', 'BVT', '布韦岛', 'Bouvet Island'],
  ['BW', 'BWA', '博茨瓦纳', 'Botswana'],
  ['BY', 'BLR', '白俄罗斯', 'Belarus'],
  ['BZ', 'BLZ', '伯利兹', 'Belize'],
  ['CA', 'CAN', '加拿大', 'Canada'],
  ['CC', 'CCK', '科科斯（基林）群岛', 'Cocos (Keeling) Islands', ['Cocos Islands']],
  ['CD', 'COD', '刚果（金）', 'Congo - Kinshasa', ['刚果民主共和国', 'Congo (DRC)']],
  ['CF', 'CAF', '中非共和国', 'Central African Republic'],
  ['CG', 'COG', '刚果（布）', 'Congo - Brazzaville', ['刚果共和国', 'Congo (Republic)']],
  ['CH', 'CHE', '瑞士', 'Switzerland'],
  ['CI', 'CIV', '科特迪瓦', 'Côte d’Ivoire', ['象牙海岸', 'Ivory Coast']],
  ['CK', 'COK', '库克群岛', 'Cook Islands'],
  ['CL', 'CHL', '智利', 'Chile'],
  ['CM', 'CMR', '喀麦隆', 'Cameroon'],
  ['CN', 'CHN', '中国', 'China'],
  ['CO', 'COL', '哥伦比亚', 'Colombia'],
  ['CR', 'CRI', '哥斯达黎加', 'Costa Rica'],
  ['CU', 'CUB', '古巴', 'Cuba'],
  ['CV', 'CPV', '佛得角', 'Cape Verde', ['Cabo Verde']],
  ['CW', 'CUW', '库拉索', 'Curaçao'],
  ['CX', 'CXR', '圣诞岛', 'Christmas Island'],
  ['CY', 'CYP', '塞浦路斯', 'Cyprus'],
  ['CZ', 'CZE', '捷克', 'Czechia', ['捷克共和国', 'Czech Republic']],
  ['DE', 'DEU', '德国', 'Germany'],
  ['DJ', 'DJI', '吉布提', 'Djibouti'],
  ['DK', 'DNK', '丹麦', 'Denmark'],
  ['DM', 'DMA', '多米尼克', 'Dominica'],
  ['DO', 'DOM', '多米尼加共和国', 'Dominican Republic'],
  ['DZ', 'DZA', '阿尔及利亚', 'Algeria'],
  ['EC', 'ECU', '厄瓜多尔', 'Ecuador'],
  ['EE', 'EST', '爱沙尼亚', 'Estonia'],
  ['EG', 'EGY', '埃及', 'Egypt'],
  ['EH', 'ESH', '西撒哈拉', 'Western Sahara'],
  ['ER', 'ERI', '厄立特里亚', 'Eritrea'],
  ['ES', 'ESP', '西班牙', 'Spain'],
  ['ET', 'ETH', '埃塞俄比亚', 'Ethiopia'],
  ['FI', 'FIN', '芬兰', 'Finland'],
  ['FJ', 'FJI', '斐济', 'Fiji'],
  ['FK', 'FLK', '福克兰群岛', 'Falkland Islands', ['福克兰群岛（马尔维纳斯群岛）', 'Falkland Islands (Islas Malvinas)']],
  ['FM', 'FSM', '密克罗尼西亚', 'Micronesia'],
  ['FO', 'FRO', '法罗群岛', 'Faroe Islands'],
  ['FR', 'FRA', '法国', 'France'],
  ['GA', 'GAB', '加蓬', 'Gabon'],
  ['GB', 'GBR', '英国', 'United Kingdom'],
  ['GD', 'GRD', '格林纳达', 'Grenada'],
  ['GE', 'GEO', '格鲁吉亚', 'Georgia'],
  ['GF', 'GUF', '法属圭亚那', 'French Guiana'],
  ['GG', 'GGY', '根西岛', 'Guernsey'],
  ['GH', 'GHA', '加纳', 'Ghana'],
  ['GI', 'GIB', '直布罗陀', 'Gibraltar'],
  ['GL', 'GRL', '格陵兰', 'Greenland'],
  ['GM', 'GMB', '冈比亚', 'Gambia'],
  ['GN', 'GIN', '几内亚', 'Guinea'],
  ['GP', 'GLP', '瓜德罗普', 'Guadeloupe'],
  ['GQ', 'GNQ', '赤道几内亚', 'Equatorial Guinea'],
  ['GR', 'GRC', '希腊', 'Greece'],
  ['GS', 'SGS', '南乔治亚和南桑威奇群岛', 'South Georgia & South Sandwich Islands'],
  ['GT', 'GTM', '危地马拉', 'Guatemala'],
  ['GU', 'GUM', '关岛', 'Guam'],
  ['GW', 'GNB', '几内亚比绍', 'Guinea-Bissau'],
  ['GY', 'GUY', '圭亚那', 'Guyana'],
  ['HK', 'HKG', '香港', 'Hong Kong', ['中国香港特别行政区', 'Hong Kong SAR China']],
  ['HM', 'HMD', '赫德岛和麦克唐纳群岛', 'Heard & McDonald Islands'],
  ['HN', 'HND', '洪都拉斯', 'Honduras'],
  ['HR', 'HRV', '克罗地亚', 'Croatia'],
  ['HT', 'HTI', '海地', 'Haiti'],
  ['HU', 'HUN', '匈牙利', 'Hungary'],
  ['ID', 'IDN', '印度尼西亚', 'Indonesia'],
  ['IE', 'IRL', '爱尔兰', 'Ireland'],
  ['IL', 'ISR', '以色列', 'Israel'],
  ['IM', 'IMN', '马恩岛', 'Isle of Man'],
  ['IN', 'IND', '印度', 'India'],
  ['IO', 'IOT', '英属印度洋领地', 'British Indian Ocean Territory'],
  ['IQ', 'IRQ', '伊拉克', 'Iraq'],
  ['IR', 'IRN', '伊朗', 'Iran'],
  ['IS', 'ISL', '冰岛', 'Iceland'],
  ['IT', 'ITA', '意大利', 'Italy'],
  ['JE', 'JEY', '泽西岛', 'Jersey'],
  ['JM', 'JAM', '牙买加', 'Jamaica'],
  ['JO', 'JOR', '约旦', 'Jordan'],
  ['JP', 'JPN', '日本', 'Japan'],
  ['KE', 'KEN', '肯尼亚', 'Kenya'],
  ['KG', 'KGZ', '吉尔吉斯斯坦', 'Kyrgyzstan'],
  ['KH', 'KHM', '柬埔寨', 'Cambodia'],
  ['KI', 'KIR', '基里巴斯', 'Kiribati'],
  ['KM', 'COM', '科摩罗', 'Comoros'],
  ['KN', 'KNA', '圣基茨和尼维斯', 'St. Kitts & Nevis'],
  ['KP', 'PRK', '朝鲜', 'North Korea'],
  ['KR', 'KOR', '韩国', 'South Korea'],
  ['KW', 'KWT', '科威特', 'Kuwait'],
  ['KY', 'CYM', '开曼群岛', 'Cayman Islands'],
  ['KZ', 'KAZ', '哈萨克斯坦', 'Kazakhstan'],
  ['LA', 'LAO', '老挝', 'Laos'],
  ['LB', 'LBN', '黎巴嫩', 'Lebanon'],
  ['LC', 'LCA', '圣卢西亚', 'St. Lucia'],
  ['LI', 'LIE', '列支敦士登', 'Liechtenstein'],
  ['LK', 'LKA', '斯里兰卡', 'Sri Lanka'],
  ['LR', 'LBR', '利比里亚', 'Liberia'],
  ['LS', 'LSO', '莱索托', 'Lesotho'],
  ['LT', 'LTU', '立陶宛', 'Lithuania'],
  ['LU', 'LUX', '卢森堡', 'Luxembourg'],
  ['LV', 'LVA', '拉脱维亚', 'Latvia'],
  ['LY', 'LBY', '利比亚', 'Libya'],
  ['MA', 'MAR', '摩洛哥', 'Morocco'],
  ['MC', 'MCO', '摩纳哥', 'Monaco'],
  ['MD', 'MDA', '摩尔多瓦', 'Moldova'],
  ['ME', 'MNE', '黑山', 'Montenegro'],
  ['MF', 'MAF', '法属圣马丁', 'St. Martin'],
  ['MG', 'MDG', '马达加斯加', 'Madagascar'],
  ['MH', 'MHL', '马绍尔群岛', 'Marshall Islands'],
  ['MK', 'MKD', '北马其顿', 'North Macedonia'],
  ['ML', 'MLI', '马里', 'Mali'],
  ['MM', 'MMR', '缅甸', 'Myanmar', ['Myanmar (Burma)']],
  ['MN', 'MNG', '蒙古', 'Mongolia'],
  ['MO', 'MAC', '澳门', 'Macao', ['中国澳门特别行政区', 'Macao SAR China']],
  ['MP', 'MNP', '北马里亚纳群岛', 'Northern Mariana Islands'],
  ['MQ', 'MTQ', '马提尼克', 'Martinique'],
  ['MR', 'MRT', '毛里塔尼亚', 'Mauritania'],
  ['MS', 'MSR', '蒙特塞拉特', 'Montserrat'],
  ['MT', 'MLT', '马耳他', 'Malta'],
  ['MU', 'MUS', '毛里求斯', 'Mauritius'],
  ['MV', 'MDV', '马尔代夫', 'Maldives'],
  ['MW', 'MWI', '马拉维', 'Malawi'],
  ['MX', 'MEX', '墨西哥', 'Mexico'],
  ['MY', 'MYS', '马来西亚', 'Malaysia'],
  ['MZ', 'MOZ', '莫桑比克', 'Mozambique'],
  ['NA', 'NAM', '纳米比亚', 'Namibia'],
  ['NC', 'NCL', '新喀里多尼亚', 'New Caledonia'],
  ['NE', 'NER', '尼日尔', 'Niger'],
  ['NF', 'NFK', '诺福克岛', 'Norfolk Island'],
  ['NG', 'NGA', '尼日利亚', 'Nigeria'],
  ['NI', 'NIC', '尼加拉瓜', 'Nicaragua'],
  ['NL', 'NLD', '荷兰', 'Netherlands'],
  ['NO', 'NOR', '挪威', 'Norway'],
  ['NP', 'NPL', '尼泊尔', 'Nepal'],
  ['NR', 'NRU', '瑙鲁', 'Nauru'],
  ['NU', 'NIU', '纽埃', 'Niue'],
  ['NZ', 'NZL', '新西兰', 'New Zealand', ['Aotearoa New Zealand']],
  ['OM', 'OMN', '阿曼', 'Oman'],
  ['PA', 'PAN', '巴拿马', 'Panama'],
  ['PE', 'PER', '秘鲁', 'Peru'],
  ['PF', 'PYF', '法属波利尼西亚', 'French Polynesia'],
  ['PG', 'PNG', '巴布亚新几内亚', 'Papua New Guinea'],
  ['PH', 'PHL', '菲律宾', 'Philippines'],
  ['PK', 'PAK', '巴基斯坦', 'Pakistan'],
  ['PL', 'POL', '波兰', 'Poland'],
  ['PM', 'SPM', '圣皮埃尔和密克隆群岛', 'St. Pierre & Miquelon'],
  ['PN', 'PCN', '皮特凯恩群岛', 'Pitcairn Islands', ['Pitcairn']],
  ['PR', 'PRI', '波多黎各', 'Puerto Rico'],
  ['PS', 'PSE', '巴勒斯坦', 'Palestine', ['巴勒斯坦领土', 'Palestinian Territories']],
  ['PT', 'PRT', '葡萄牙', 'Portugal'],
  ['PW', 'PLW', '帕劳', 'Palau'],
  ['PY', 'PRY', '巴拉圭', 'Paraguay'],
  ['QA', 'QAT', '卡塔尔', 'Qatar'],
  ['RE', 'REU', '留尼汪', 'Réunion'],
  ['RO', 'ROU', '罗马尼亚', 'Romania'],
  ['RS', 'SRB', '塞尔维亚', 'Serbia'],
  ['RU', 'RUS', '俄罗斯', 'Russia'],
  ['RW', 'RWA', '卢旺达', 'Rwanda'],
  ['SA', 'SAU', '沙特阿拉伯', 'Saudi Arabia'],
  ['SB', 'SLB', '所罗门群岛', 'Solomon Islands'],
  ['SC', 'SYC', '塞舌尔', 'Seychelles'],
  ['SD', 'SDN', '苏丹', 'Sudan'],
  ['SE', 'SWE', '瑞典', 'Sweden'],
  ['SG', 'SGP', '新加坡', 'Singapore'],
  ['SH', 'SHN', '圣赫勒拿', 'St. Helena'],
  ['SI', 'SVN', '斯洛文尼亚', 'Slovenia'],
  ['SJ', 'SJM', '斯瓦尔巴和扬马延', 'Svalbard & Jan Mayen'],
  ['SK', 'SVK', '斯洛伐克', 'Slovakia'],
  ['SL', 'SLE', '塞拉利昂', 'Sierra Leone'],
  ['SM', 'SMR', '圣马力诺', 'San Marino'],
  ['SN', 'SEN', '塞内加尔', 'Senegal'],
  ['SO', 'SOM', '索马里', 'Somalia'],
  ['SR', 'SUR', '苏里南', 'Suriname'],
  ['SS', 'SSD', '南苏丹', 'South Sudan'],
  ['ST', 'STP', '圣多美和普林西比', 'São Tomé & Príncipe'],
  ['SV', 'SLV', '萨尔瓦多', 'El Salvador'],
  ['SX', 'SXM', '荷属圣马丁', 'Sint Maarten'],
  ['SY', 'SYR', '叙利亚', 'Syria'],
  ['SZ', 'SWZ', '斯威士兰', 'Eswatini', ['Swaziland']],
  ['TC', 'TCA', '特克斯和凯科斯群岛', 'Turks & Caicos Islands'],
  ['TD', 'TCD', '乍得', 'Chad'],
  ['TF', 'ATF', '法属南部领地', 'French Southern Territories'],
  ['TG', 'TGO', '多哥', 'Togo'],
  ['TH', 'THA', '泰国', 'Thailand'],
  ['TJ', 'TJK', '塔吉克斯坦', 'Tajikistan'],
  ['TK', 'TKL', '托克劳', 'Tokelau'],
  ['TL', 'TLS', '东帝汶', 'Timor-Leste', ['East Timor']],
  ['TM', 'TKM', '土库曼斯坦', 'Turkmenistan'],
  ['TN', 'TUN', '突尼斯', 'Tunisia'],
  ['TO', 'TON', '汤加', 'Tonga'],
  ['TR', 'TUR', '土耳其', 'Türkiye', ['Turkey']],
  ['TT', 'TTO', '特立尼达和多巴哥', 'Trinidad & Tobago'],
  ['TV', 'TUV', '图瓦卢', 'Tuvalu'],
  ['TW', 'TWN', '台湾', 'Taiwan'],
  ['TZ', 'TZA', '坦桑尼亚', 'Tanzania'],
  ['UA', 'UKR', '乌克兰', 'Ukraine'],
  ['UG', 'UGA', '乌干达', 'Uganda'],
  ['UM', 'UMI', '美国本土外小岛屿', 'U.S. Outlying Islands'],
  ['US', 'USA', '美国', 'United States'],
  ['UY', 'URY', '乌拉圭', 'Uruguay'],
  ['UZ', 'UZB', '乌兹别克斯坦', 'Uzbekistan'],
  ['VA', 'VAT', '梵蒂冈', 'Vatican City'],
  ['VC', 'VCT', '圣文森特和格林纳丁斯', 'St. Vincent & Grenadines'],
  ['VE', 'VEN', '委内瑞拉', 'Venezuela'],
  ['VG', 'VGB', '英属维尔京群岛', 'British Virgin Islands'],
  ['VI', 'VIR', '美属维尔京群岛', 'U.S. Virgin Islands'],
  ['VN', 'VNM', '越南', 'Vietnam'],
  ['VU', 'VUT', '瓦努阿图', 'Vanuatu'],
  ['WF', 'WLF', '瓦利斯和富图纳', 'Wallis & Futuna'],
  ['WS', 'WSM', '萨摩亚', 'Samoa'],
  ['YE', 'YEM', '也门', 'Yemen'],
  ['YT', 'MYT', '马约特', 'Mayotte'],
  ['ZA', 'ZAF', '南非', 'South Africa'],
  ['ZM', 'ZMB', '赞比亚', 'Zambia'],
  ['ZW', 'ZWE', '津巴布韦', 'Zimbabwe'],
]

// These aliases are intentionally separate from the standards-based catalog.
// Short Latin aliases are matched only as standalone uppercase codes by default.
const COMMON_ALIAS_ROWS = [
  ['AE', ['阿联酋', '阿聯酋', '迪拜', '阿布扎比', 'Dubai', 'Abu Dhabi', 'DXB', 'AUH', 'UAE']],
  ['AU', ['澳洲', '澳大利亞', '悉尼', '墨尔本', '墨爾本', '布里斯班', '珀斯', 'Sydney', 'Melbourne', 'Brisbane', 'Perth', 'SYD', 'MEL', 'BNE']],
  ['BR', ['圣保罗', 'São Paulo', 'Sao Paulo', 'GRU']],
  ['CA', ['多伦多', '多倫多', '温哥华', '溫哥華', '蒙特利尔', '蒙特利爾', '渥太华', '渥太華', '卡尔加里', '卡爾加里', 'Toronto', 'Vancouver', 'Montreal', 'Ottawa', 'Calgary', 'YYZ', 'YVR', 'YUL']],
  ['CH', ['苏黎世', 'Zurich', 'ZRH']],
  ['CN', ['北京', '上海', '广州', '深圳', '杭州', '成都', '重庆']],
  ['DE', ['德國', '法兰克福', '法蘭克福', '柏林', 'Frankfurt', 'Berlin', 'BER']],
  ['ES', ['马德里', '巴塞罗那', 'Madrid', 'Barcelona', 'MAD', 'BCN']],
  ['FI', ['赫尔辛基', 'Helsinki', 'HEL']],
  ['FR', ['法國', '巴黎', '马赛', '馬賽', 'Paris', 'Marseille', 'CDG', 'ORY', 'MRS']],
  ['GB', ['英國', 'Britain', 'Great Britain', 'England', '伦敦', '倫敦', '曼彻斯特', '曼徹斯特', 'London', 'Manchester', 'LON', 'LHR', 'MAN', 'UK']],
  ['HK', ['Hongkong', '九龙', '九龍', 'Kowloon', '新界', '沙田', '荃湾', '荃灣', '葵涌', '深港', '沪港', '滬港', '广港', '廣港', '京港', '杭港']],
  ['ID', ['印尼', '印度尼西亞', '雅加达', '雅加達', 'Jakarta', 'CGK']],
  ['IN', ['孟买', '金奈', '新德里', 'Mumbai', 'Chennai', 'New Delhi', 'BOM', 'MAA', 'DEL']],
  ['IT', ['米兰', '罗马', 'Milan', 'Rome', 'MXP', 'FCO']],
  ['JP', ['东京', '東京', '大阪', '关西', '關西', '埼玉', '川日', '泉日', '深日', '沪日', '滬日', '广日', '廣日', '京日', '杭日', 'Tokyo', 'Osaka', 'Kansai', 'NRT', 'HND', 'KIX', 'TYO', 'OSA']],
  ['KR', ['韓國', 'Republic of Korea', '首尔', '首爾', '春川', '仁川', 'Seoul', 'Chuncheon', 'Incheon', 'ICN']],
  ['MY', ['马来', '馬來', '馬來西亞', '吉隆坡', 'Kuala Lumpur', 'KUL']],
  ['MO', ['澳門', 'Macau']],
  ['NL', ['荷蘭', '阿姆斯特丹', 'Amsterdam', 'AMS']],
  ['NZ', ['新西蘭', '紐西蘭', '奥克兰', '奧克蘭', 'Auckland', 'AKL']],
  ['PH', ['菲律賓', '马尼拉', '馬尼拉', 'Manila', 'MNL']],
  ['PL', ['华沙', 'Warsaw', 'WAW']],
  ['RU', ['俄羅斯', 'Russian Federation', '莫斯科', 'Moscow', 'SVO']],
  ['SE', ['斯德哥尔摩', 'Stockholm', 'ARN']],
  ['SG', ['狮城', 'SIN']],
  ['TH', ['泰國', '曼谷', 'Bangkok', 'BKK']],
  ['TR', ['伊斯坦布尔', 'Istanbul', 'IST']],
  ['TW', ['中国台湾', '中國台灣', '中國臺灣', '中国台北', '中國台北', '中华台北', '中華台北', '台灣', '臺灣', '台北', '臺北', '新北', '彰化', '高雄', '台中', '臺中', 'Taipei', 'New Taipei', 'Kaohsiung', 'Taichung', 'TPE', 'TSA', 'KHH', 'ROC']],
  ['US', ['美國', '美西', '美东', '美東', '洛杉矶', '洛杉磯', '旧金山', '舊金山', '硅谷', '矽谷', '西雅图', '西雅圖', '芝加哥', '纽约', '紐約', '达拉斯', '達拉斯', '阿什本', '凤凰城', '鳳凰城', '亚特兰大', '亞特蘭大', '波特兰', '波特蘭', '俄勒冈', '俄勒岡', '费利蒙', '費利蒙', '拉斯维加斯', '拉斯維加斯', '圣何塞', '聖何塞', '圣克拉拉', '聖克拉拉', '迈阿密', '邁阿密', '华盛顿', '華盛頓', 'UnitedStates', 'Los Angeles', 'San Francisco', 'Silicon Valley', 'Seattle', 'Chicago', 'New York', 'Dallas', 'Ashburn', 'Phoenix', 'Atlanta', 'Portland', 'Fremont', 'Las Vegas', 'Santa Clara', 'Miami', 'LAX', 'SFO', 'SEA', 'ORD', 'JFK', 'EWR', 'NYC', 'DFW', 'IAD', 'PHX', 'ATL', 'MIA', 'SJC']],
  ['VN', ['越南', '胡志明市', '河内', '河內', 'Ho Chi Minh City', 'Hanoi', 'SGN', 'HAN']],
  ['ZA', ['约翰内斯堡', '开普敦', 'Johannesburg', 'Cape Town', 'JNB', 'CPT']],
]

// These codes frequently mean a protocol, platform, product, line type or city
// in proxy names. Their full names, flags and non-conflicting codes still work.
const AMBIGUOUS_SHORT_CODES = new Set([
  'AI',
  'AM',
  'AUS',
  'CAN',
  'CF',
  'FRA',
  'HND',
  'IND',
  'IO',
  'LA',
  'LB',
  'MAC',
  'MCO',
  'ME',
  'NF',
  'PER',
  'PM',
  'SS',
  'TLS',
  'TR',
  'TV',
  'WS',
])

const REGIONS = REGION_ROWS.map(row => ({
  code: row[0],
  alpha3: row[1],
  zh: row[2],
  en: row[3],
  aliases: row[4] || [],
  flag: flagFromCode(row[0]),
}))

const REGION_BY_CODE = new Map(REGIONS.map(region => [region.code, region]))
const PHRASE_ENTRIES = []
const CODE_ENTRIES = []

for (const region of REGIONS) {
  addMatchEntry(region.code, region.zh)
  addMatchEntry(region.code, region.en)
  for (const alias of region.aliases) addMatchEntry(region.code, alias)
  addCodeEntry(region.code, region.code)
  addCodeEntry(region.code, region.alpha3)
}

for (const row of COMMON_ALIAS_ROWS) {
  for (const alias of row[1]) addMatchEntry(row[0], alias)
}

function operator(proxies = []) {
  if (!Array.isArray(proxies) || proxies.length === 0) return []

  const counters = new Map()
  return proxies.map(proxy => {
    const originalName = String(proxy && proxy.name != null ? proxy.name : '')
    const result = resolveRegion(originalName)
    if (result.state !== 'matched') return proxy

    const count = (counters.get(result.region.code) || 0) + 1
    counters.set(result.region.code, count)
    return updateProxy(
      proxy,
      `${result.region.zh} ${String(count).padStart(2, '0')}`,
    )
  })
}

function resolveRegion(name) {
  const matchName = String(name)
  const normalized = normalizeForMatching(matchName)
  const evidence = []
  for (const region of REGIONS) {
    let offset = 0
    while (true) {
      const index = matchName.indexOf(region.flag, offset)
      if (index === -1) break
      evidence.push({
        code: region.code,
        tier: 1,
        start: -1,
        end: -1,
        value: region.flag,
      })
      offset = index + region.flag.length
    }
  }

  for (const entry of PHRASE_ENTRIES) {
    for (const occurrence of findOccurrences(normalized.folded, entry.value)) {
      evidence.push({ ...entry, ...occurrence, tier: 3 })
    }
  }

  const codeText = normalized.plain
  for (const entry of CODE_ENTRIES) {
    if (AMBIGUOUS_SHORT_CODES.has(entry.value)) continue
    for (const occurrence of findOccurrences(codeText, entry.value, true)) {
      evidence.push({ ...entry, ...occurrence, tier: 2 })
    }
  }

  const resolvedEvidence = removeContainedEvidence(deduplicateEvidence(evidence))
  const highestTier = resolvedEvidence.reduce(
    (highest, value) => Math.max(highest, value.tier || 0),
    0,
  )
  const decisiveEvidence = resolvedEvidence.filter(value => value.tier === highestTier)
  const codes = [...new Set(decisiveEvidence.map(value => value.code))]

  if (codes.length === 0) {
    return { state: 'unmatched', region: null }
  }
  if (codes.length > 1) {
    return { state: 'ambiguous', region: null }
  }
  return {
    state: 'matched',
    region: REGION_BY_CODE.get(codes[0]),
  }
}

function normalizeForMatching(value) {
  let text = String(value == null ? '' : value)
  try {
    text = text.normalize('NFKD')
  } catch {}
  text = text
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[’']/g, '')
    .replace(/\./g, '')
    .replace(/&/g, ' and ')
    .replace(/\bsaint\b/gi, 'st')
    .replace(/[^0-9A-Za-z\u3400-\u9FFF]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
  return { plain: text, folded: text.toLowerCase() }
}

function addMatchEntry(code, value) {
  const normalized = normalizeForMatching(value).plain
  if (!normalized) return
  if (/^[A-Za-z]{2,3}$/.test(normalized)) {
    addCodeEntry(code, normalized.toUpperCase())
    return
  }
  const folded = normalized.toLowerCase()
  if (!PHRASE_ENTRIES.some(entry => entry.code === code && entry.value === folded)) {
    PHRASE_ENTRIES.push({ code, value: folded })
  }
}

function addCodeEntry(code, value) {
  const token = String(value || '').toUpperCase()
  if (!/^[A-Z]{2,3}$/.test(token)) return
  if (!CODE_ENTRIES.some(entry => entry.code === code && entry.value === token)) {
    CODE_ENTRIES.push({ code, value: token })
  }
}

function findOccurrences(text, needle, disallowLeadingDigit = false) {
  const occurrences = []
  let offset = 0
  while (offset <= text.length - needle.length) {
    const start = text.indexOf(needle, offset)
    if (start === -1) break
    const end = start + needle.length
    const before = start > 0 ? text[start - 1] : ''
    const after = end < text.length ? text[end] : ''
    const startsClean =
      start === 0 ||
      (!/[A-Za-z]/.test(before) && (!disallowLeadingDigit || !/[0-9]/.test(before)))
    const endsClean = end === text.length || !/[A-Za-z]/.test(after)
    const containsLatin = /[A-Za-z]/.test(needle)
    if (!containsLatin || (startsClean && endsClean)) occurrences.push({ start, end })
    offset = start + Math.max(1, needle.length)
  }
  return occurrences
}

function deduplicateEvidence(evidence) {
  const seen = new Set()
  return evidence.filter(item => {
    const key = `${item.code}|${item.tier}|${item.start}|${item.end}|${item.value || ''}`
    if (seen.has(key)) return false
    seen.add(key)
    return true
  })
}

function removeContainedEvidence(evidence) {
  return evidence.filter((item, index) => {
    if (item.start < 0) return true
    const itemLength = item.end - item.start
    return !evidence.some((other, otherIndex) => {
      if (otherIndex === index || other.start < 0) return false
      const otherLength = other.end - other.start
      return (
        otherLength > itemLength &&
        other.start <= item.start &&
        other.end >= item.end
      )
    })
  })
}

function updateProxy(proxy, name) {
  if (!proxy || typeof proxy !== 'object') return proxy
  const nameChanged = String(proxy.name == null ? '' : proxy.name) !== name
  if (!nameChanged) return proxy
  const output = { ...proxy }
  output.name = name
  return output
}

function flagFromCode(code) {
  return [...code]
    .map(character => String.fromCodePoint(127397 + character.charCodeAt(0)))
    .join('')
}

// Sub-Store evaluates this file directly and does not define `module`.
// The conditional export keeps runtime behavior unchanged while allowing CI tests.
if (typeof module !== 'undefined') {
  module.exports = { operator }
}
