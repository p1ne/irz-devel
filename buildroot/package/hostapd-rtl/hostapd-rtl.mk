################################################################################
#
# hostapd-rtl
#
################################################################################

HOSTAPD_RTL_VERSION = 2.6
HOSTAPD_RTL_SITE = http://hostap.epitest.fi/releases
HOSTAPD_RTL_SUBDIR = hostapd
HOSTAPD_RTL_SOURCE = hostapd-$(HOSTAPD_RTL_VERSION).tar.gz
HOSTAPD_RTL_CONFIG = $(HOSTAPD_RTL_DIR)/$(HOSTAPD_RTL_SUBDIR)/.config
HOSTAPD_RTL_DEPENDENCIES = host-pkgconf libnl
HOSTAPD_RTL_CFLAGS = $(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include/libnl3/
HOSTAPD_RTL_LICENSE = BSD-3c
HOSTAPD_RTL_LICENSE_FILES = README
HOSTAPD_RTL_CONFIG_SET =

HOSTAPD_RTL_CONFIG_ENABLE = \
	CONFIG_DRIVER_RTW \
	CONFIG_INTERNAL_LIBTOMMATH \
	CONFIG_LIBNL32 \

HOSTAPD_RTL_CONFIG_DISABLE = \
  CONFIG_DRIVER_HOSTAP \
  CONFIG_DRIVER_NL80211 \
  CONFIG_ERP \
  CONFIG_FULL_DYNAMIC_VLAN \
  CONFIG_HS20 \
  CONFIG_IAPP \
  CONFIG_IEEE80211AC \
  CONFIG_IEEE80211R \
  CONFIG_IEEE80211W \
  CONFIG_INTERNAL_LIBTOMMATH_FAST \
  CONFIG_INTERWORKING \
  CONFIG_IPV6 \
  CONFIG_NO_ACCOUNTING \
  CONFIG_NO_RADIUS \
  CONFIG_PEERKEY \
  CONFIG_PKCS12 \
  CONFIG_RSN_PREAUTH \
  CONFIG_VLAN_NETLINK

# libnl-3 needs -lm (for rint) and -lpthread if linking statically
# And library order matters hence stick -lnl-3 first since it's appended
# in the hostapd Makefiles as in LIBS+=-lnl-3 ... thus failing
ifeq ($(BR2_STATIC_LIBS),y)
HOSTAPD_RTL_LIBS += -lnl-3 -lm -lpthread
endif

# Try to use openssl if it's already available
ifeq ($(BR2_PACKAGE_OPENSSL),y)
HOSTAPD_RTL_DEPENDENCIES += openssl
HOSTAPD_RTL_LIBS += $(if $(BR2_STATIC_LIBS),-lcrypto -lz)
HOSTAPD_RTL_CONFIG_EDITS += 's/\#\(CONFIG_TLS=openssl\)/\1/'
else
HOSTAPD_RTL_CONFIG_DISABLE += CONFIG_EAP_PWD
HOSTAPD_RTL_CONFIG_EDITS += 's/\#\(CONFIG_TLS=\).*/\1internal/'
endif

ifeq ($(BR2_PACKAGE_HOSTAPD_RTL_ACS),y)
HOSTAPD_RTL_CONFIG_ENABLE += CONFIG_ACS
endif

ifeq ($(BR2_PACKAGE_HOSTAPD_RTL_EAP),y)
HOSTAPD_RTL_CONFIG_ENABLE += \
	CONFIG_EAP \
	CONFIG_RADIUS_SERVER \

# Enable both TLS v1.1 (CONFIG_TLSV11) and v1.2 (CONFIG_TLSV12)
HOSTAPD_RTL_CONFIG_ENABLE += CONFIG_TLSV1
else
HOSTAPD_RTL_CONFIG_DISABLE += CONFIG_EAP
HOSTAPD_RTL_CONFIG_ENABLE += \
	CONFIG_NO_ACCOUNTING \
	CONFIG_NO_RADIUS
endif

ifeq ($(BR2_PACKAGE_HOSTAPD_RTL_WPS),y)
HOSTAPD_RTL_CONFIG_ENABLE += CONFIG_WPS
endif

define HOSTAPD_RTL_CONFIGURE_CMDS
	cp $(@D)/hostapd/defconfig $(HOSTAPD_RTL_CONFIG)
	sed -i $(patsubst %,-e 's/^#\(%\)/\1/',$(HOSTAPD_RTL_CONFIG_ENABLE)) \
		$(patsubst %,-e 's/^\(%\)/#\1/',$(HOSTAPD_RTL_CONFIG_DISABLE)) \
		$(patsubst %,-e '1i%=y',$(HOSTAPD_RTL_CONFIG_SET)) \
		$(patsubst %,-e %,$(HOSTAPD_RTL_CONFIG_EDITS)) \
		$(HOSTAPD_RTL_CONFIG)
endef

define HOSTAPD_RTL_BUILD_CMDS
	$(TARGET_MAKE_ENV) CFLAGS="$(HOSTAPD_RTL_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" LIBS="$(HOSTAPD_RTL_LIBS)" \
		$(MAKE) CC="$(TARGET_CC)" -C $(@D)/$(HOSTAPD_RTL_SUBDIR)
endef

define HOSTAPD_RTL_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 -D $(@D)/$(HOSTAPD_RTL_SUBDIR)/hostapd \
		$(TARGET_DIR)/usr/sbin/hostapd
	$(INSTALL) -m 0755 -D $(@D)/$(HOSTAPD_RTL_SUBDIR)/hostapd_cli \
		$(TARGET_DIR)/usr/bin/hostapd_cli
	$(INSTALL) -m 0644 -D $(@D)/$(HOSTAPD_RTL_SUBDIR)/hostapd.conf \
		$(TARGET_DIR)/etc/hostapd.conf
endef

$(eval $(generic-package))
