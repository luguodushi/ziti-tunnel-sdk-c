set(COMPONENT_NAME "${PROJECT_NAME}")
set(CPACK_INSTALL_CMAKE_PROJECTS "${CMAKE_CURRENT_BINARY_DIR};${PROJECT_NAME};${COMPONENT_NAME};/")
#[[
set(COMPONENT_GROUP "${COMPONENT_NAME}_cg")
cpack_add_component_group("${COMPONENT_GROUP}")
cpack_add_component("${COMPONENT_NAME}" GROUP "${COMPONENT_GROUP}")
set(CPACK_COMPONENTS_GROUPING "ONE_PER_GROUP")
get_cmake_property(CPACK_COMPONENTS_ALL COMPONENTS)
list(REMOVE_ITEM CPACK_COMPONENTS_ALL "Unspecified")
set(CPACK_RPM_COMPONENT_INSTALL "ON")
]]

set(PACKAGING_BASE "${CMAKE_CURRENT_SOURCE_DIR}/package")
set(PACKAGING_SCRIPTS "${PACKAGING_BASE}/scripts")

find_program(AWK awk REQUIRED)

set(OS_RELEASE_EXECUTABLE "${PACKAGING_SCRIPTS}/os_release.awk")
execute_process(COMMAND "${OS_RELEASE_EXECUTABLE}" "ID"
                OUTPUT_VARIABLE CPACK_OS_RELEASE_ID
                OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND "${OS_RELEASE_EXECUTABLE}" "VERSION_ID"
                OUTPUT_VARIABLE CPACK_OS_RELEASE_VERSION
                OUTPUT_STRIP_TRAILING_WHITESPACE)

message("CPACK_OS_RELEASE_ID: ${CPACK_OS_RELEASE_ID}")
message("CPACK_OS_RELEASE_VERSION: ${CPACK_OS_RELEASE_VERSION}")

set(CPACK_RPM_DISTRIBUTIONS "redhat;rocky;centos;fedora;rhel")
set(CPACK_DEB_DISTRIBUTIONS "debian;ubuntu;mint;pop")

if(CPACK_OS_RELEASE_ID IN_LIST CPACK_DEB_DISTRIBUTIONS)
	set(CPACK_GENERATOR "DEB")
elseif(CPACK_OS_RELEASE_ID IN_LIST CPACK_RPM_DISTRIBUTIONS)
	set(CPACK_GENERATOR "RPM")
else()
    message(FATAL_ERROR "failed to match OS_RELEASE_ID: ${OS_RELEASE_ID}")
endif()

set(CPACK_PROJECT_CONFIG_FILE ${PACKAGING_BASE}/CPackGenConfig.cmake)

set(CPACK_PACKAGE_CONTACT "support@netfoundry.io")
set(CPACK_PACKAGE_NAME "${COMPONENT_NAME}")
set(CPACK_PACKAGE_RELEASE 1)
set(CPACK_PACKAGE_VENDOR "NetFoundry")
set(CPACK_PACKAGE_VERSION ${PROJECT_SEMVER})
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_PACKAGE_RELEASE}")

set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/openziti")
set(CPACK_BIN_DIR "${CPACK_PACKAGING_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}")
set(CPACK_ETC_DIR "${CPACK_PACKAGING_INSTALL_PREFIX}/${CMAKE_INSTALL_SYSCONFDIR}")
set(CPACK_SHARE_DIR "${CPACK_PACKAGING_INSTALL_PREFIX}/${CMAKE_INSTALL_DATAROOTDIR}")

set(INSTALL_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/package")

set(SYSTEMD_IN_DIR "${PACKAGING_BASE}/systemd")
set(SYSTEMD_SERVICE_NAME "${CPACK_PACKAGE_NAME}")
set(SYSTEMD_UNIT_FILE_NAME "${SYSTEMD_SERVICE_NAME}.service")
set(SYSTEMD_EXECSTARTPRE "${SYSTEMD_SERVICE_NAME}.sh")
set(SYSTEMD_ENV_FILE "${SYSTEMD_SERVICE_NAME}.env")

set(ZITI_IDENTITY_DIR "${CPACK_ETC_DIR}/identities")

set(ZITI_STATE_DIR "/var/lib/ziti")

install(DIRECTORY DESTINATION "${CPACK_ETC_DIR}"
        COMPONENT "${COMPONENT_NAME}")

install(DIRECTORY DESTINATION "${ZITI_IDENTITY_DIR}"
        COMPONENT "${COMPONENT_NAME}")

configure_file("${SYSTEMD_IN_DIR}/${SYSTEMD_ENV_FILE}.in"
	           "${INSTALL_OUT_DIR}/${SYSTEMD_ENV_FILE}"
	           @ONLY)

configure_file("${SYSTEMD_IN_DIR}/${SYSTEMD_UNIT_FILE_NAME}.in"
               "${INSTALL_OUT_DIR}/${SYSTEMD_UNIT_FILE_NAME}"
               @ONLY)

configure_file("${SYSTEMD_IN_DIR}/${SYSTEMD_EXECSTARTPRE}.in"
	           "${INSTALL_OUT_DIR}/${SYSTEMD_EXECSTARTPRE}"
	           @ONLY)

install(FILES "${INSTALL_OUT_DIR}/${SYSTEMD_ENV_FILE}"
        DESTINATION "${CPACK_ETC_DIR}"
        COMPONENT "${COMPONENT_NAME}")

install(FILES "${INSTALL_OUT_DIR}/${SYSTEMD_UNIT_FILE_NAME}"
	    DESTINATION "${CPACK_SHARE_DIR}"
        COMPONENT "${COMPONENT_NAME}")


install(FILES "${INSTALL_OUT_DIR}/${SYSTEMD_EXECSTARTPRE}"
        DESTINATION "${CPACK_BIN_DIR}"
        PERMISSIONS
            OWNER_READ OWNER_WRITE OWNER_EXECUTE
            GROUP_READ GROUP_EXECUTE
            WORLD_READ WORLD_EXECUTE
        COMPONENT "${COMPONENT_NAME}")

install(DIRECTORY DESTINATION "${ZITI_STATE_DIR}"
        COMPONENT "${COMPONENT_NAME}")

if("RPM" IN_LIST CPACK_GENERATOR)
    set(RPM_IN_DIR "${PACKAGING_BASE}/rpm")
    set(RPM_PRE_INSTALL_IN "${RPM_IN_DIR}/pre.sh.in")
    set(RPM_POST_INSTALL_IN "${RPM_IN_DIR}/post.sh.in")
    set(RPM_PRE_UNINSTALL_IN "${RPM_IN_DIR}/preun.sh.in")
    set(RPM_POST_UNINSTALL_IN "${RPM_IN_DIR}/postun.sh.in")

    set(CPACK_RPM_PRE_INSTALL "${INSTALL_OUT_DIR}/pre.sh")
    set(CPACK_RPM_POST_INSTALL "${INSTALL_OUT_DIR}/post.sh")
    set(CPACK_RPM_PRE_UNINSTALL "${INSTALL_OUT_DIR}/preun.sh")
    set(CPACK_RPM_POST_UNINSTALL "${INSTALL_OUT_DIR}/postun.sh")

    configure_file("${RPM_PRE_INSTALL_IN}" "${CPACK_RPM_PRE_INSTALL}" @ONLY)
    configure_file("${RPM_POST_INSTALL_IN}" "${CPACK_RPM_POST_INSTALL}" @ONLY)
    configure_file("${RPM_PRE_UNINSTALL_IN}" "${CPACK_RPM_PRE_UNINSTALL}" @ONLY)
    configure_file("${RPM_POST_UNINSTALL_IN}" "${CPACK_RPM_POST_UNINSTALL}" @ONLY)
endif()

if("DEB" IN_LIST CPACK_GENERATOR)
    set(DEB_IN_DIR "${PACKAGING_BASE}/deb")
    set(DEB_CONFFILES_IN "${DEB_IN_DIR}/conffiles.in")
    set(DEB_POST_INSTALL_IN "${DEB_IN_DIR}/postinst.in")
    set(DEB_PRE_UNINSTALL_IN "${DEB_IN_DIR}/prerm.in")
    set(DEB_POST_UNINSTALL_IN "${DEB_IN_DIR}/postrm.in")

    set(CPACK_DEB_CONFFILES "${INSTALL_OUT_DIR}/conffiles")
    set(CPACK_DEB_POST_INSTALL "${INSTALL_OUT_DIR}/postinst")
    set(CPACK_DEB_PRE_UNINSTALL "${INSTALL_OUT_DIR}/prerm")
    set(CPACK_DEB_POST_UNINSTALL "${INSTALL_OUT_DIR}/postrm")

    configure_file("${DEB_CONFFILES_IN}" "${CPACK_DEB_CONFFILES}" @ONLY)
    configure_file("${DEB_POST_INSTALL_IN}" "${CPACK_DEB_POST_INSTALL}" @ONLY)
    configure_file("${DEB_PRE_UNINSTALL_IN}" "${CPACK_DEB_PRE_UNINSTALL}" @ONLY)
    configure_file("${DEB_POST_UNINSTALL_IN}" "${CPACK_DEB_POST_UNINSTALL}" @ONLY)
endif()
