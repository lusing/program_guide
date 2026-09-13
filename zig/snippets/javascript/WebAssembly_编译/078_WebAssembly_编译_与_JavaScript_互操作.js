// 加载 Wasm 模块
const wasmBytes = await Deno.readFile("./math.wasm");
const wasmModule = new WebAssembly.Module(wasmBytes);
const wasmInstance = new WebAssembly.Instance(wasmModule, {
    env: {
        console_log: (ptr) => {
            // 从内存中读取字符串
            const memory = wasmInstance.exports.memory;
            const decoder = new TextDecoder();
            let str = "";
            while (true) {
                const byte = memory.buffer.getUint8(ptr++);
                if (byte === 0) break;
                str += String.fromCharCode(byte);
            }
            console.log(str);
        }
    }
});

// 调用导出的函数
const result = wasmInstance.exports.add(10, 20);
console.log("10 + 20 =", result);
