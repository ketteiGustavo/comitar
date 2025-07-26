#!/usr/bin/env bats

load 'helpers/bats-support/load'
load 'helpers/bats-assert/load'

@test "should show help message" {
  run comitar --help
  assert_output --partial "USO:"
}

@test "should show version" {
  run comitar --version
  assert_output --partial "Versão:"
}
