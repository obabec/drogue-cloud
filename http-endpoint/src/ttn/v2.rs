use crate::{
    telemetry::PublishCommonOptions,
    ttn::{publish_uplink, Uplink},
};
use actix_web::{web, HttpResponse};
use drogue_cloud_endpoint_common::{
    auth::DeviceAuthenticator,
    downstream::DownstreamSender,
    error::{EndpointError, HttpEndpointError},
    x509::ClientCertificateChain,
};
use drogue_ttn::v2;

pub async fn publish_v2(
    sender: web::Data<DownstreamSender>,
    auth: web::Data<DeviceAuthenticator>,
    web::Query(opts): web::Query<PublishCommonOptions>,
    req: web::HttpRequest,
    body: web::Bytes,
    cert: Option<ClientCertificateChain>,
) -> Result<HttpResponse, HttpEndpointError> {
    let uplink: v2::Uplink = serde_json::from_slice(&body).map_err(|err| {
        log::info!("Failed to decode payload: {}", err);
        EndpointError::InvalidFormat {
            source: Box::new(err),
        }
    })?;

    publish_uplink(
        sender,
        auth,
        opts,
        req,
        cert,
        body,
        Uplink {
            device_id: uplink.dev_id,
            port: uplink.port.to_string(),
            time: uplink.metadata.time,
            is_retry: Some(uplink.is_retry),
            hardware_address: uplink.hardware_serial,
            payload_raw: uplink.payload_raw,
            payload_fields: uplink.payload_fields,
        },
    )
    .await
}
