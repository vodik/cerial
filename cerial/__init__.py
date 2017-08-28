from .struct import Struct  # noqa


UDP = Struct('UDP',
    ('sport', 'uint16'),
    ('dport', 'uint16'),
    ('len', 'uint16'),
    ('csum', 'uint16'),
    endianness='!'
)
