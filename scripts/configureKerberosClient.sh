#!/bin/bash
echo "==================================================================================="
echo "==== Kerberos Client =============================================================="
echo "==================================================================================="
KADMIN_PRINCIPAL_FULL=$KADMIN_PRINCIPAL@$REALM

echo "REALM: $REALM"
echo "KADMIN_PRINCIPAL_FULL: $KADMIN_PRINCIPAL_FULL"
echo "KADMIN_PASSWORD: $KADMIN_PASSWORD"
echo ""

function kadminCommand {
    kadmin -p $KADMIN_PRINCIPAL_FULL -w $KADMIN_PASSWORD -q "$1"
}

echo "==================================================================================="
echo "==== /etc/krb5.conf ==============================================================="
echo "==================================================================================="
tee /etc/krb5.conf <<EOF
[libdefaults]
	default_realm = $REALM
	dns_canonicalize_hostname = false
	dns_lookup_realm = false
 	dns_lookup_kdc = false

[realms]
	$REALM = {
		kdc = ${KDC_HOST}
		admin_server = ${KDC_HOST}
	}
EOF
echo ""

echo "==================================================================================="
echo "==== Testing ======================================================================"
echo "==================================================================================="
until kadminCommand "list_principals $KADMIN_PRINCIPAL_FULL"; do
  >&2 echo "KDC is unavailable - sleeping 1 sec"
  sleep 1
done
echo "KDC and Kadmin are operational"
echo ""

echo "==================================================================================="
echo "==== Add kafka and zookeeper principals for host ${HOSTNAME} ======================"
echo "==================================================================================="
echo "Add zookeeper user"
kadminCommand "addprinc -pw zookeeper zookeeper/$(hostname -f)@${REALM}"
echo "Create zookeeper keytab"
kadminCommand "xst -k /zookeeper.keytab zookeeper/$(hostname -f)"
echo "Add kafka user"
kadminCommand "addprinc -pw kafka kafka/$(hostname -f)@${REALM}"
echo "Create kafka keytab"
kadminCommand "xst -k /kafka.keytab kafka/$(hostname -f)"
echo ""
exit 0
