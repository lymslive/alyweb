#! /bin/bash

echo '{"api":"create","data":{"date":"2019-01-01","short":"a short title","long":"a maybe long text","signed":[{"room":"A1001","state":"1"},{"room":"A1002","state":"2"},{"room":"B1002","state":"0"}]}}' | ./japi.pl
