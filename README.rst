======
cerial
======

.. image:: https://travis-ci.org/vodik/cerial.svg?branch=master
    :target: https://travis-ci.org/vodik/cerial

Fast, simple, and more pythonic binary serializer library.

Cerial combines Python 3 features, Cython, and memory views to create
a fast and easy library for packing and unpacking binary structures.

Removes a lot of the boilerplate that sometimes ends up surrounding
struct when used for serialization.

-------
Example
-------

Here's a quick example of how to use cerial to handle a UDP packet.
First we define the structure:

.. code-block:: python

    >>> UDP = Struct('UDP',
    ...    ('sport', 'uint16'),
    ...    ('dport', 'uint16'),
    ...    ('len', 'uint16'),
    ...    ('csum', 'uint16'),
    ...    endianness='!'
    ...)

Unlike the builtin struct library, cerial needs the fields to be bound
to a name. This is because we expose the binary structure with
dictionary interface instead of as a tuple of values.

Now that we have a structure defined, we can use to parse data:

.. code-block:: python

    >>> data = bytearray(b'\x08R\x02\x02\x00w\xa9k')
    >>> hdr = UDP.parse(data)
    >>> hdr
    <UDP b'\x08R\x02\x02\x00w\xa9k'>

We can now inspect the binary structure:

.. code-block:: python

    >>> hdr['csum']
    43371
    >>> dict(hdr)
    {'csum': 43371, 'len': 119, 'sport': 2130, 'dport': 514}
    >>> bytes(hdr)
    b'\x08R\x02\x02\x00w\xa9k'

And we can also update individual fields, which will directly write to
the underlying memory view, no rendering step needed.

.. code-block:: python

    >>> hdr['csum'] = 0xffff
    >>> data
    bytearray(b'\x08R\x02\x02\x00w\xff\xff')
    >>> bytes(hdr)
    b'\x08R\x02\x02\x00w\xff\xff'

----
TODO
----

- Feature parity with the various primitives the struct library
  supports
- First class support for bit fields
- Improve performance
- Support readonly memoryviews (e.g. support bytes). An upstream
  Cython issue.

-----------
Performance
-----------

Currently slightly slower than the struct module, but as far as I can
tell, significantly faster than other similar libraries like pypacker
or scrapy at parsing packets.
