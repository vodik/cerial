# cython: language_level=3
# cython: auto_pickle=False
# cython: infer_types=True
from cython cimport Py_buffer, Py_ssize_t
from cython.operator cimport dereference as deref, preincrement as inc
from libc.stdint cimport uint8_t, uint16_t, uint32_t
from libc.string cimport memcpy
from libcpp.unordered_map cimport unordered_map
from libcpp.string cimport string


cdef extern from *:
    uint16_t __builtin_bswap16(uint16_t x)
    uint32_t __builtin_bswap32(uint32_t x)


cdef object unpack_uint8(uint8_t *data):
    return data[0]


cdef object pack_uint8(uint8_t *data, object obj):
    data[0] = obj


cdef object unpack_uint16_le(uint8_t *data):
    cdef uint16_t value
    memcpy(&value, data, sizeof(value))
    return value


cdef object pack_uint16_le(uint8_t *data, object obj):
    cdef uint16_t value = obj
    memcpy(data, &value, sizeof(value))


cdef object unpack_uint32_le(uint8_t *data):
    cdef uint32_t value
    memcpy(&value, data, sizeof(value))
    return value


cdef object pack_uint32_le(uint8_t *data, object obj):
    cdef uint32_t value = obj
    memcpy(data, &value, sizeof(value))


cdef object unpack_uint16_be(uint8_t *data):
    cdef uint16_t value
    memcpy(&value, data, sizeof(value))
    return __builtin_bswap16(value)


cdef object pack_uint16_be(uint8_t *data, object obj):
    cdef uint16_t value = obj
    value = __builtin_bswap16(value)
    memcpy(data, &value, sizeof(value))


cdef object unpack_uint32_be(uint8_t *data):
    cdef uint32_t value
    memcpy(&value, data, sizeof(value))
    return __builtin_bswap32(value)


cdef object pack_uint32_be(uint8_t *data, object obj):
    cdef uint32_t value = obj
    value = __builtin_bswap32(value)
    memcpy(data, &value, sizeof(value))


cdef struct formatdef:
    Py_ssize_t offset
    object (*pack)(uint8_t *, object)
    object (*unpack)(uint8_t *)


ctypedef unordered_map[string, formatdef] formatmap


cdef class View:
    cdef Struct struct
    cdef uint8_t[:] buf
    cdef Py_ssize_t shape[1]
    cdef Py_ssize_t strides[1]

    def __cinit__(self, Struct struct, uint8_t[:] buf):
        self.struct = struct
        self.buf = buf
        self.shape[0] = len(struct)
        self.strides[0] = 1

    def keys(self):
        yield from self.struct.keys()

    def __getitem__(self, key):
        try:
            formatdef = self.struct.definition(key.encode())
            return formatdef.unpack(&self.buf[formatdef.offset])
        except IndexError:
            raise AttributeError(key) from None

    def __setitem__(self, key, value):
        try:
            formatdef = self.struct.definition(key.encode())
            formatdef.pack(&self.buf[formatdef.offset], value)
        except IndexError:
            raise AttributeError(key) from None

    def __len__(self):
        return self.shape[0]

    def __getbuffer__(self, Py_buffer *buffer, int flags):
        buffer.buf = &self.buf[0]
        buffer.format = 'B'
        buffer.internal = NULL
        buffer.itemsize = 1
        buffer.len = self.shape[0]
        buffer.ndim = len(self.shape)
        buffer.obj = self
        buffer.readonly = 0
        buffer.shape = self.shape
        buffer.strides = self.strides
        buffer.suboffsets = NULL

    def __releasebuffer__(self, Py_buffer *buffer):
        pass

    def __copy__(self):
        memory = bytearray(self)
        return self.struct.parse(memory)

    def __repr__(self):
        return f'<{self.struct.name} {bytes(self.buf)}>'


cdef class Struct:
    cdef Py_ssize_t length
    cdef formatmap offsets
    cdef str name

    def __cinit__(self, name, *fields, endianness='='):
        cdef Py_ssize_t offset = 0
        if endianness == '=':
            endianness = '<'

        for key, field in fields:
            key = key.encode()
            if field == 'uint8':
                self.offsets[key] = formatdef(offset=offset,
                                              pack=pack_uint8,
                                              unpack=unpack_uint8)
                offset += sizeof(uint8_t)
            elif field == 'uint16':
                if endianness == '<':
                    self.offsets[key] = formatdef(offset=offset,
                                                  pack=pack_uint16_le,
                                                  unpack=unpack_uint16_le)
                else:
                    self.offsets[key] = formatdef(offset=offset,
                                                  pack=pack_uint16_be,
                                                  unpack=unpack_uint16_be)
                offset += sizeof(uint16_t)
            elif field == 'uint32':
                if endianness == '<':
                    self.offsets[key] = formatdef(offset=offset,
                                                  pack=pack_uint32_le,
                                                  unpack=unpack_uint32_le)
                else:
                    self.offsets[key] = formatdef(offset=offset,
                                                  pack=pack_uint32_be,
                                                  unpack=unpack_uint32_be)
                offset += sizeof(uint32_t)

        self.length = offset
        self.name = name

    def __len__(self):
        return self.length

    cdef formatdef *definition(self, key) except + :
        return &self.offsets.at(key)

    def keys(self):
        it = self.offsets.begin()
        while it != self.offsets.end():
            yield deref(it).first.decode()
            inc(it)

    def parse(self, data not None):
        return View.__new__(View, self, data)

    def __call__(self, **fields):
        view = View.__new__(View, self, bytearray(len(self)))
        for key, value in fields.items():
            view[key] = value
        return view

    def __repr__(self):
        return f'<Struct {self.name} len={len(self)}>'
