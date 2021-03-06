<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template name="iso639_2to3">
<xsl:param name="l"/>
<xsl:choose>
<xsl:when test="$l='aa'">aar</xsl:when>
<xsl:when test="$l='ab'">abk</xsl:when>
<xsl:when test="$l='af'">afr</xsl:when>
<xsl:when test="$l='ak'">aka</xsl:when>
<xsl:when test="$l='sq'">sqi</xsl:when>
<xsl:when test="$l='am'">amh</xsl:when>
<xsl:when test="$l='ar'">ara</xsl:when>
<xsl:when test="$l='an'">arg</xsl:when>
<xsl:when test="$l='hy'">hye</xsl:when>
<xsl:when test="$l='as'">asm</xsl:when>
<xsl:when test="$l='av'">ava</xsl:when>
<xsl:when test="$l='ae'">ave</xsl:when>
<xsl:when test="$l='ay'">aym</xsl:when>
<xsl:when test="$l='az'">aze</xsl:when>
<xsl:when test="$l='ba'">bak</xsl:when>
<xsl:when test="$l='bm'">bam</xsl:when>
<xsl:when test="$l='eu'">eus</xsl:when>
<xsl:when test="$l='be'">bel</xsl:when>
<xsl:when test="$l='bn'">ben</xsl:when>
<xsl:when test="$l='bh'">bih</xsl:when>
<xsl:when test="$l='bi'">bis</xsl:when>
<xsl:when test="$l='bo'">bod</xsl:when>
<xsl:when test="$l='bs'">bos</xsl:when>
<xsl:when test="$l='br'">bre</xsl:when>
<xsl:when test="$l='bg'">bul</xsl:when>
<xsl:when test="$l='my'">mya</xsl:when>
<xsl:when test="$l='ca'">cat</xsl:when>
<xsl:when test="$l='cs'">ces</xsl:when>
<xsl:when test="$l='ch'">cha</xsl:when>
<xsl:when test="$l='ce'">che</xsl:when>
<xsl:when test="$l='zh'">zho</xsl:when>
<xsl:when test="$l='cu'">chu</xsl:when>
<xsl:when test="$l='cv'">chv</xsl:when>
<xsl:when test="$l='kw'">cor</xsl:when>
<xsl:when test="$l='co'">cos</xsl:when>
<xsl:when test="$l='cr'">cre</xsl:when>
<xsl:when test="$l='cy'">cym</xsl:when>
<xsl:when test="$l='cs'">ces</xsl:when>
<xsl:when test="$l='da'">dan</xsl:when>
<xsl:when test="$l='de'">deu</xsl:when>
<xsl:when test="$l='dv'">div</xsl:when>
<xsl:when test="$l='nl'">nld</xsl:when>
<xsl:when test="$l='dz'">dzo</xsl:when>
<xsl:when test="$l='el'">ell</xsl:when>
<xsl:when test="$l='en'">eng</xsl:when>
<xsl:when test="$l='eo'">epo</xsl:when>
<xsl:when test="$l='et'">est</xsl:when>
<xsl:when test="$l='eu'">eus</xsl:when>
<xsl:when test="$l='ee'">ewe</xsl:when>
<xsl:when test="$l='fo'">fao</xsl:when>
<xsl:when test="$l='fa'">fas</xsl:when>
<xsl:when test="$l='fj'">fij</xsl:when>
<xsl:when test="$l='fi'">fin</xsl:when>
<xsl:when test="$l='fr'">fra</xsl:when>
<xsl:when test="$l='fy'">fry</xsl:when>
<xsl:when test="$l='ff'">ful</xsl:when>
<xsl:when test="$l='ka'">kat</xsl:when>
<xsl:when test="$l='de'">deu</xsl:when>
<xsl:when test="$l='gd'">gla</xsl:when>
<xsl:when test="$l='ga'">gle</xsl:when>
<xsl:when test="$l='gl'">glg</xsl:when>
<xsl:when test="$l='gv'">glv</xsl:when>
<xsl:when test="$l='el'">ell</xsl:when>
<xsl:when test="$l='gn'">grn</xsl:when>
<xsl:when test="$l='gu'">guj</xsl:when>
<xsl:when test="$l='ht'">hat</xsl:when>
<xsl:when test="$l='ha'">hau</xsl:when>
<xsl:when test="$l='he'">heb</xsl:when>
<xsl:when test="$l='hz'">her</xsl:when>
<xsl:when test="$l='hi'">hin</xsl:when>
<xsl:when test="$l='ho'">hmo</xsl:when>
<xsl:when test="$l='hr'">hrv</xsl:when>
<xsl:when test="$l='hu'">hun</xsl:when>
<xsl:when test="$l='hy'">hye</xsl:when>
<xsl:when test="$l='ig'">ibo</xsl:when>
<xsl:when test="$l='is'">isl</xsl:when>
<xsl:when test="$l='io'">ido</xsl:when>
<xsl:when test="$l='ii'">iii</xsl:when>
<xsl:when test="$l='iu'">iku</xsl:when>
<xsl:when test="$l='ie'">ile</xsl:when>
<xsl:when test="$l='ia'">ina</xsl:when>
<xsl:when test="$l='id'">ind</xsl:when>
<xsl:when test="$l='ik'">ipk</xsl:when>
<xsl:when test="$l='is'">isl</xsl:when>
<xsl:when test="$l='it'">ita</xsl:when>
<xsl:when test="$l='jv'">jav</xsl:when>
<xsl:when test="$l='ja'">jpn</xsl:when>
<xsl:when test="$l='kl'">kal</xsl:when>
<xsl:when test="$l='kn'">kan</xsl:when>
<xsl:when test="$l='ks'">kas</xsl:when>
<xsl:when test="$l='ka'">kat</xsl:when>
<xsl:when test="$l='kr'">kau</xsl:when>
<xsl:when test="$l='kk'">kaz</xsl:when>
<xsl:when test="$l='km'">khm</xsl:when>
<xsl:when test="$l='ki'">kik</xsl:when>
<xsl:when test="$l='rw'">kin</xsl:when>
<xsl:when test="$l='ky'">kir</xsl:when>
<xsl:when test="$l='kv'">kom</xsl:when>
<xsl:when test="$l='kg'">kon</xsl:when>
<xsl:when test="$l='ko'">kor</xsl:when>
<xsl:when test="$l='kj'">kua</xsl:when>
<xsl:when test="$l='ku'">kur</xsl:when>
<xsl:when test="$l='lo'">lao</xsl:when>
<xsl:when test="$l='la'">lat</xsl:when>
<xsl:when test="$l='lv'">lav</xsl:when>
<xsl:when test="$l='li'">lim</xsl:when>
<xsl:when test="$l='ln'">lin</xsl:when>
<xsl:when test="$l='lt'">lit</xsl:when>
<xsl:when test="$l='lb'">ltz</xsl:when>
<xsl:when test="$l='lu'">lub</xsl:when>
<xsl:when test="$l='lg'">lug</xsl:when>
<xsl:when test="$l='mk'">mkd</xsl:when>
<xsl:when test="$l='mh'">mah</xsl:when>
<xsl:when test="$l='ml'">mal</xsl:when>
<xsl:when test="$l='mi'">mri</xsl:when>
<xsl:when test="$l='mr'">mar</xsl:when>
<xsl:when test="$l='ms'">msa</xsl:when>
<xsl:when test="$l='mk'">mkd</xsl:when>
<xsl:when test="$l='mg'">mlg</xsl:when>
<xsl:when test="$l='mt'">mlt</xsl:when>
<xsl:when test="$l='mn'">mon</xsl:when>
<xsl:when test="$l='mi'">mri</xsl:when>
<xsl:when test="$l='ms'">msa</xsl:when>
<xsl:when test="$l='my'">mya</xsl:when>
<xsl:when test="$l='na'">nau</xsl:when>
<xsl:when test="$l='nv'">nav</xsl:when>
<xsl:when test="$l='nr'">nbl</xsl:when>
<xsl:when test="$l='nd'">nde</xsl:when>
<xsl:when test="$l='ng'">ndo</xsl:when>
<xsl:when test="$l='ne'">nep</xsl:when>
<xsl:when test="$l='nl'">nld</xsl:when>
<xsl:when test="$l='nn'">nno</xsl:when>
<xsl:when test="$l='nb'">nob</xsl:when>
<xsl:when test="$l='no'">nor</xsl:when>
<xsl:when test="$l='ny'">nya</xsl:when>
<xsl:when test="$l='oc'">oci</xsl:when>
<xsl:when test="$l='oj'">oji</xsl:when>
<xsl:when test="$l='or'">ori</xsl:when>
<xsl:when test="$l='om'">orm</xsl:when>
<xsl:when test="$l='os'">oss</xsl:when>
<xsl:when test="$l='pa'">pan</xsl:when>
<xsl:when test="$l='fa'">fas</xsl:when>
<xsl:when test="$l='pi'">pli</xsl:when>
<xsl:when test="$l='pl'">pol</xsl:when>
<xsl:when test="$l='pt'">por</xsl:when>
<xsl:when test="$l='ps'">pus</xsl:when>
<xsl:when test="$l='qu'">que</xsl:when>
<xsl:when test="$l='rm'">roh</xsl:when>
<xsl:when test="$l='ro'">ron</xsl:when>
<xsl:when test="$l='rn'">run</xsl:when>
<xsl:when test="$l='ru'">rus</xsl:when>
<xsl:when test="$l='sg'">sag</xsl:when>
<xsl:when test="$l='sa'">san</xsl:when>
<xsl:when test="$l='si'">sin</xsl:when>
<xsl:when test="$l='sk'">slk</xsl:when>
<xsl:when test="$l='sl'">slv</xsl:when>
<xsl:when test="$l='se'">sme</xsl:when>
<xsl:when test="$l='sm'">smo</xsl:when>
<xsl:when test="$l='sn'">sna</xsl:when>
<xsl:when test="$l='sd'">snd</xsl:when>
<xsl:when test="$l='so'">som</xsl:when>
<xsl:when test="$l='st'">sot</xsl:when>
<xsl:when test="$l='es'">spa</xsl:when>
<xsl:when test="$l='sq'">sqi</xsl:when>
<xsl:when test="$l='sc'">srd</xsl:when>
<xsl:when test="$l='sr'">srp</xsl:when>
<xsl:when test="$l='ss'">ssw</xsl:when>
<xsl:when test="$l='su'">sun</xsl:when>
<xsl:when test="$l='sw'">swa</xsl:when>
<xsl:when test="$l='sv'">swe</xsl:when>
<xsl:when test="$l='ty'">tah</xsl:when>
<xsl:when test="$l='ta'">tam</xsl:when>
<xsl:when test="$l='tt'">tat</xsl:when>
<xsl:when test="$l='te'">tel</xsl:when>
<xsl:when test="$l='tg'">tgk</xsl:when>
<xsl:when test="$l='tl'">tgl</xsl:when>
<xsl:when test="$l='th'">tha</xsl:when>
<xsl:when test="$l='bo'">bod</xsl:when>
<xsl:when test="$l='ti'">tir</xsl:when>
<xsl:when test="$l='to'">ton</xsl:when>
<xsl:when test="$l='tn'">tsn</xsl:when>
<xsl:when test="$l='ts'">tso</xsl:when>
<xsl:when test="$l='tk'">tuk</xsl:when>
<xsl:when test="$l='tr'">tur</xsl:when>
<xsl:when test="$l='tw'">twi</xsl:when>
<xsl:when test="$l='ug'">uig</xsl:when>
<xsl:when test="$l='uk'">ukr</xsl:when>
<xsl:when test="$l='ur'">urd</xsl:when>
<xsl:when test="$l='uz'">uzb</xsl:when>
<xsl:when test="$l='ve'">ven</xsl:when>
<xsl:when test="$l='vi'">vie</xsl:when>
<xsl:when test="$l='vo'">vol</xsl:when>
<xsl:when test="$l='cy'">cym</xsl:when>
<xsl:when test="$l='wa'">wln</xsl:when>
<xsl:when test="$l='wo'">wol</xsl:when>
<xsl:when test="$l='xh'">xho</xsl:when>
<xsl:when test="$l='yi'">yid</xsl:when>
<xsl:when test="$l='yo'">yor</xsl:when>
<xsl:when test="$l='za'">zha</xsl:when>
<xsl:when test="$l='zh'">zho</xsl:when>
<xsl:when test="$l='zu'">zul</xsl:when>
</xsl:choose>
</xsl:template>
</xsl:stylesheet>