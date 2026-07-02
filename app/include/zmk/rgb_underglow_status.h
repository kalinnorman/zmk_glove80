/*
 * Copyright (c) 2024 The ZMK Contributors
 *
 * SPDX-License-Identifier: MIT
 */

#pragma once

#include <zephyr/sys/util.h>
#include <zephyr/types.h>

/*
 * Wire payload pushed from a BLE split central to a peripheral so the
 * peripheral can render its own zmk,underglow-indicators status LEDs
 * locally, without needing any of the central-only APIs
 * (zmk_keymap_layer_active, zmk_ble_*, zmk_endpoints_*,
 * zmk_split_central_get_peripheral_battery_level) that aren't compiled into
 * peripheral builds.
 *
 * The sizes below are fixed, fork-defined constants rather than being
 * derived from the `underglow_indicators` devicetree node, because this
 * header is also included from central-only firmware (e.g. a keyboard
 * dongle) that has no such node to size against. The receiving peripheral
 * clamps against its own DT_PROP_LEN(...) when consuming this struct.
 */

#define ZMK_RGB_UNDERGLOW_STATUS_MAX_LAYERS 8
#define ZMK_RGB_UNDERGLOW_STATUS_MAX_BLE_PROFILES 5

#define ZMK_RGB_UNDERGLOW_STATUS_BATTERY_UNKNOWN 0xFF

struct zmk_rgb_underglow_peripheral_status {
    /* Battery level (0-100) of this peripheral's peer, or
     * ZMK_RGB_UNDERGLOW_STATUS_BATTERY_UNKNOWN if unavailable. */
    uint8_t peer_battery_level;
    /* Bit i set means layer i is active (zmk_keymap_layer_active(i)). */
    uint8_t active_layers;
    /* Raw enum zmk_transport value of the currently selected endpoint. */
    uint8_t active_transport;
    /* Raw bool: zmk_endpoints_preferred_transport_is_active(). */
    uint8_t preferred_transport_is_active;
    /* zmk_ble_active_profile_index(). */
    uint8_t active_ble_profile_index;
    /* Raw int8_t zmk_ble_profile_status(i) values, one per profile slot. */
    uint8_t ble_profile_status[ZMK_RGB_UNDERGLOW_STATUS_MAX_BLE_PROFILES];
    /* Raw enum zmk_usb_conn_state value. */
    uint8_t usb_conn_state;
} __packed;

BUILD_ASSERT(sizeof(struct zmk_rgb_underglow_peripheral_status) <= 20,
             "underglow status payload must fit in a single default-MTU BLE write");

/* Implemented in src/rgb_underglow.c. Called on the peripheral (from the
 * split BLE service's GATT write callback) whenever the central pushes a
 * fresh status snapshot. */
void zmk_rgb_underglow_set_peripheral_status(
    const struct zmk_rgb_underglow_peripheral_status *status);
