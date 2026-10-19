"""Inline external-offset buffers for mobile runtimes; preserve all weights/ops."""
from pathlib import Path
import hashlib
import json
import flatbuffers
import numpy as np
from tensorflow.lite.python import schema_py_generated as schema

ROOT = Path(__file__).resolve().parents[2]

def pack(source, target):
    data=source.read_bytes()
    parsed=schema.Model.GetRootAsModel(data,0)
    model=schema.ModelT.InitFromObj(parsed)
    packed=0
    for buffer in model.buffers:
        if buffer.offset:
            start,size=int(buffer.offset),int(buffer.size)
            assert 0 <= start < len(data) and start+size <= len(data)
            buffer.data=np.frombuffer(data[start:start+size],dtype=np.uint8).copy()
            buffer.offset=0;buffer.size=0;packed+=1
    builder=flatbuffers.Builder(len(data))
    builder.Finish(model.Pack(builder),file_identifier=b'TFL3')
    output=bytes(builder.Output())
    check=schema.Model.GetRootAsModel(output,0)
    # Verify every tensor buffer byte, operator graph and quantization through
    # object API after resolving only buffer storage. No model math changes.
    check_model=schema.ModelT.InitFromObj(check)
    for original,result in zip(model.buffers,check_model.buffers):
        assert np.array_equal(original.data,result.data)
        assert result.offset==0
    assert parsed.SubgraphsLength()==check.SubgraphsLength()
    assert parsed.Subgraphs(0).OperatorsLength()==check.Subgraphs(0).OperatorsLength()
    target.write_bytes(output)
    return dict(source_sha256=hashlib.sha256(data).hexdigest(),target_sha256=hashlib.sha256(output).hexdigest(),buffers_inlined=packed,size_bytes=len(output))

if __name__=='__main__':
    source=ROOT/'assets/models/acne_detector.tflite'
    target=ROOT/'assets/models/acne_detector_mobile.tflite'
    result=pack(source,target)
    # Equal tensors and equal numeric outputs on the same normalized input.
    import tensorflow as tf
    def run(path,x):
        i=tf.lite.Interpreter(model_path=str(path));i.allocate_tensors()
        i.set_tensor(i.get_input_details()[0]['index'],x);i.invoke()
        return i.get_tensor(i.get_output_details()[0]['index'])
    x=np.random.default_rng(201).random((1,3,640,640),dtype=np.float32)
    a,b=run(source,x),run(target,x)
    result['verification_runtime']=f'TensorFlow {tf.__version__} CPU'
    result['verification_input_seed']=201
    result['verification_input_shape']=[1,3,640,640]
    result['max_absolute_output_difference']=float(np.max(np.abs(a-b)))
    assert np.array_equal(a,b)
    (ROOT/'assets/models/mobile-packaging.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2),flush=True)
