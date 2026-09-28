from pathlib import Path
import urllib.request,io,concurrent.futures
from PIL import Image,ImageChops
root=Path(__file__).resolve().parents[1]
# Search-returned product photos; originals remain in product_images.
assets={
 'phone':('8iCE5jVF5G5n6TaR','https://www.amazon.com/Apple-iPhone-15-Pro-Titanium/dp/B0CMZBXYWX'),
 'samsung':('iLf9EweJUiuy4n0h','https://www.amazon.com/clp/B0D364RMMP'),
 'oneplus':('DY5liEe3jSE3eaCs','https://www.amazon.com/OnePlus-12-512GB-Silky-Black/dp/B0D2RBX6L1'),
 'laptop':('Lt2d22NPFrJn1iHZ','https://www.walmart.com/ip/5463172166'),
 'earbuds':('ky1fhxYPkf87bBax','https://www.amazon.com/clp/B0C4TLFZSZ'),
 'shoe':('T2hvE5pS44mH9HN2','https://www.walmart.com/ip/257458075'),
 'book':('jjMhysFypAueDUqU','https://jamesclear.com/atomic-habits'),
 'money':('cyVpuleoumEX06a2','https://www.amazon.com/Psychology-Money-Timeless-lessons-happiness/dp/0857197681'),
 'rich':('RcqjqNOd36lQ4UzD','https://www.amazon.com/Rich-Dad-Poor-Teach-Middle/dp/1612681131'),
 'shirt':('gCdpCDnXLEX90JiB','https://freesvg.org/white-t-shirt-vector-graphics'),
 'jeans':('aWt23f33EE0lpVoc','https://www.walmart.com/ip/248712931'),
 'mixer':('BzxGfEmb0yu2KDEi','https://www.ebay.com/itm/286000309592')}
def load(item):
 name,(key,source)=item
 if (root/f'public/static/images/{name}.webp').exists():return
 request=urllib.request.Request('https://sspark.genspark.ai/i/'+key+'?width=1000',headers={'User-Agent':'Mozilla/5.0'})
 with urllib.request.urlopen(request,timeout=50) as r: im=Image.open(io.BytesIO(r.read())).convert('RGB')
 # Trim near-white margins; no modification of trademarks or text.
 diff=ImageChops.difference(im,Image.new('RGB',im.size,'white')).convert('L').point(lambda x:255 if x>25 else 0)
 box=diff.getbbox()
 if box:im=im.crop(box)
 im.thumbnail((700,700))
 canvas=Image.new('RGB',(800,800),'white');canvas.paste(im,((800-im.width)//2,(800-im.height)//2));canvas.save(root/f'public/static/images/{name}.webp','WEBP',quality=88)
 print(name,im.size)
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:list(pool.map(load,assets.items()))
mapping={1:('phone',1),2:('samsung',0),3:('oneplus',0),4:('samsung',1),5:('laptop',0),6:('laptop',1),7:('earbuds',1),8:('earbuds',0),9:('earbuds',1),10:('shirt',1),11:('shirt',1),12:('jeans',0),13:('book',0),14:('money',0),15:('rich',0),16:('mixer',0),17:('shoe',0),18:('shoe',1),19:('phone',1)}
# No mismatched brand photos: generic illustrated assets for unsupported products.
for pid in [4,6,7,9,18]:
 name='placeholder';mapping[pid]=(name,1)
rows=[]
for pid,(name,illustrative) in mapping.items():
 source=assets[name][1] if name in assets else 'Original generic placeholder'
 path=f'/static/images/{name}.webp' if name in assets else '/static/images/placeholder.svg'
 rows.append(f"({pid},'{path}','{source}',{illustrative})")
(root/'migrations/0003_media.sql').write_text('INSERT INTO product_media(product_id,image_url,source_url,is_illustrative) VALUES\n'+',\n'.join(rows)+';\n')
