# Tipi, an API toolkit in Ruby

*NOTE*: Tipi is currently under active development and may change at any
time. There's little documentation about *how* you use Tipi; this README
is mostly for answering *why*.

Tipi is a toolkit for writing RESTful, resource-oriented APIs in Ruby.
More specifically, Tipi is designed for an "API-first" approach where
your frontend application (written in Rails/Sinatra) can be fully
implemented using your public API. We believe that the best APIs are
designed when you have a concrete application in mind. Your product
should be that first application.

Tipi is focused on RESTful, stateless, resource-oriented APIs, but
specifically tries to decouple your API from *HTTP*. Yes, you can mount
your API as an HTTP service, but you are not limited by HTTP. The most
important part of Tipi is that **you write your API using regular Ruby
classes/methods**. This is your real public API. Your frontend
application doesn't have to access your API over HTTP, it can just talk
directly to the classes.

The value of Tipi is that it puts certain constraints on your API. These
constraints make it possible to always switch out the backend you're
talking to.

