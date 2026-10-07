"""Validate the built place's actual replication boundary, not just file locations."""
import sys
import xml.etree.ElementTree as ET
root=ET.parse(sys.argv[1]).getroot()
def name(item):
    return item.findtext('./Properties/string[@name="Name"]')
def inspect(item,path=()):
    path=(*path,name(item) or item.get('class'))
    source=item.findtext('./Properties/ProtectedString[@name="Source"]') or ''
    if 'answer=' in source:
        assert 'ServerScriptService' in path, f'Answer key replicated at {path}'
        assert name(item)=='QuestionBank'
    if source and 'EmmaStudyClient' in path:
        assert 'payload.prompt' in source and 'QuestionPrompt' in source
        assert 'Enum.CameraType.Custom' in source
    for child in item.findall('Item'):
        inspect(child,path)
for item in root.findall('Item'):
    inspect(item)
print('PASS: built place keeps answer keys in ServerScriptService and includes readable prompt/client camera')
